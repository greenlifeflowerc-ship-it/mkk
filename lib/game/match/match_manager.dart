import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/constants/game_constants.dart';
import '../../core/utils/math_utils.dart';
import '../combat/collision_resolver.dart';
import '../combat/combo_counter.dart';
import '../combat/hit_event.dart';
import '../combat/projectile.dart';
import '../combat/push_resolver.dart';
import '../fighter/facing.dart';
import '../fighter/fighter_component.dart';
import '../fighter/fighter_state.dart';
import 'round_state.dart';

/// Owns the complete best-of-3 match flow and per-tick combat resolution:
/// fighter ticks, body push, hit detection, hitstop, facing, round timer,
/// KO slow-mo and round/match transitions. Pure logic — no rendering — so
/// the whole match is unit-testable. Notifies listeners every tick for the
/// Flutter HUD.
class MatchManager extends ChangeNotifier {
  MatchManager({
    required this.p1,
    required this.p2,
    this.onHitFeedback,
    this.onTimeScale,
  });

  final FighterComponent p1;
  final FighterComponent p2;

  /// Camera shake / SFX hook; called for every connecting hit.
  final void Function(HitEvent event)? onHitFeedback;

  /// KO slow-mo hook; the game maps this onto the ticker's time scale.
  final void Function(double scale)? onTimeScale;

  RoundPhase phase = RoundPhase.intro;
  int phaseTick = 0;
  int roundNumber = 1;
  int p1Wins = 0;
  int p2Wins = 0;

  /// Remaining round time in ticks; -1 second every 60 fighting ticks.
  int timerTicks = GameConstants.roundTimerSeconds * 60;
  int _nextRoundSeconds = GameConstants.roundTimerSeconds;

  int hitstopTicks = 0;
  int totalTicks = 0;

  /// Delayed "ghost" health fractions for the HUD damage trail.
  double ghostP1 = 1;
  double ghostP2 = 1;
  int lastHitTickP1 = -1000;
  int lastHitTickP2 = -1000;

  /// Live projectiles (cleared on round reset).
  final List<ActiveProjectile> projectiles = [];

  /// Current combos: hits landed ON each player without recovery.
  final ComboCounter comboOnP1 = ComboCounter();
  final ComboCounter comboOnP2 = ComboCounter();

  /// Frozen popup values so "N HITS" lingers briefly after a combo drops.
  int comboPopupOnP1 = 0;
  int comboPopupOnP2 = 0;
  int comboPopupTickOnP1 = -1000;
  int comboPopupTickOnP2 = -1000;

  String? _roundWinnerId; // null while undecided, '' for a draw.

  int get timerSeconds => (timerTicks / 60).ceil();
  bool get inputsEnabled => phase == RoundPhase.fighting;
  String? get matchWinnerId => p1Wins >= GameConstants.roundsToWin
      ? p1.playerId
      : p2Wins >= GameConstants.roundsToWin
          ? p2.playerId
          : null;

  String get announcerText => switch (phase) {
        RoundPhase.intro => phaseTick < RoundTiming.announceRound
            ? 'ROUND $roundNumber'
            : 'FIGHT!',
        RoundPhase.fighting => phaseTick < 20 ? 'FIGHT!' : '',
        RoundPhase.koSlowmo => timerTicks <= 0 ? 'TIME' : 'K.O.',
        RoundPhase.roundEnd => _roundWinnerId == null || _roundWinnerId!.isEmpty
            ? 'DRAW'
            : '$_roundWinnerId WINS',
        RoundPhase.matchEnd => '',
      };

  /// Advances the whole match by one fixed logic tick.
  void tick() {
    totalTicks++;
    switch (phase) {
      case RoundPhase.intro:
        _tickFighters();
        if (phaseTick >= RoundTiming.introTotal) {
          _enterPhase(RoundPhase.fighting);
        }
      case RoundPhase.fighting:
        _tickCombat();
      case RoundPhase.koSlowmo:
        _tickFighters();
        if (phaseTick == RoundTiming.victoryPoseDelay) {
          _strikeVictoryPose();
        }
        if (phaseTick >= RoundTiming.koSlowmo) {
          onTimeScale?.call(1.0);
          _enterPhase(RoundPhase.roundEnd);
        }
      case RoundPhase.roundEnd:
        _tickFighters();
        if (phaseTick >= RoundTiming.roundEndHold) {
          if (matchWinnerId != null) {
            _enterPhase(RoundPhase.matchEnd);
          } else {
            _startNextRound();
          }
        }
      case RoundPhase.matchEnd:
        break;
    }
    _updateGhostBars();
    phaseTick++;
    notifyListeners();
  }

  void _enterPhase(RoundPhase next) {
    phase = next;
    phaseTick = 0;
  }

  void _tickFighters() {
    p1.logicTick(totalTicks, acceptInput: false);
    p2.logicTick(totalTicks, acceptInput: false);
    _resolvePush();
  }

  void _tickCombat() {
    if (hitstopTicks > 0) {
      hitstopTicks--;
      return;
    }
    if (!p1.fsm.state.isStunned) comboOnP1.reset();
    if (!p2.fsm.state.isStunned) comboOnP2.reset();

    p1.logicTick(totalTicks);
    p2.logicTick(totalTicks);
    _collectProjectiles();
    _resolvePush();
    _resolveHits();
    _tickProjectiles();
    _updateFacing();

    timerTicks = math.max(0, timerTicks - 1);
    final p1Dead = p1.health.isKo;
    final p2Dead = p2.health.isKo;
    if (p1Dead || p2Dead || timerTicks <= 0) {
      _endRound(p1Dead: p1Dead, p2Dead: p2Dead);
    }
  }

  void _endRound({required bool p1Dead, required bool p2Dead}) {
    if (p1Dead && p2Dead) {
      _roundWinnerId = ''; // Double KO: draw.
    } else if (p1Dead || p2Dead) {
      _roundWinnerId = p1Dead ? p2.playerId : p1.playerId;
    } else {
      // Time out: higher HP wins, tie is a draw.
      _roundWinnerId = p1.health.current > p2.health.current
          ? p1.playerId
          : p2.health.current < p1.health.current
              ? p2.playerId
              : '';
      _strikeTimeoutPoses();
    }
    if (_roundWinnerId == p1.playerId) p1Wins++;
    if (_roundWinnerId == p2.playerId) p2Wins++;
    // Draws replay the round in sudden death; otherwise full timer.
    _nextRoundSeconds = (_roundWinnerId?.isEmpty ?? false)
        ? RoundTiming.suddenDeathSeconds
        : GameConstants.roundTimerSeconds;
    onTimeScale?.call(GameConstants.koSlowmoRate);
    _enterPhase(RoundPhase.koSlowmo);
  }

  void _strikeVictoryPose() {
    if (_roundWinnerId == p1.playerId && !p1.fsm.state.isStunned) {
      p1.fsm.forceState(FighterState.victory);
    } else if (_roundWinnerId == p2.playerId && !p2.fsm.state.isStunned) {
      p2.fsm.forceState(FighterState.victory);
    }
  }

  void _strikeTimeoutPoses() {
    if (_roundWinnerId == p1.playerId) {
      p2.fsm.forceState(FighterState.defeat);
    } else if (_roundWinnerId == p2.playerId) {
      p1.fsm.forceState(FighterState.defeat);
    }
  }

  void _startNextRound() {
    roundNumber++;
    _resetRound();
    _enterPhase(RoundPhase.intro);
  }

  /// Full rematch from round 1 (victory screen / quit-match). Meter only
  /// resets here — it persists between rounds of a match.
  void restartMatch() {
    roundNumber = 1;
    p1Wins = 0;
    p2Wins = 0;
    p1.meter.reset();
    p2.meter.reset();
    _nextRoundSeconds = GameConstants.roundTimerSeconds;
    _resetRound();
    _enterPhase(RoundPhase.intro);
    notifyListeners();
  }

  void _resetRound() {
    final stageCenter =
        (GameConstants.stageLeftBound + GameConstants.stageRightBound) / 2;
    p1.resetForRound(
      startX: stageCenter - GameConstants.spawnOffsetX,
      facing: Facing.right,
    );
    p2.resetForRound(
      startX: stageCenter + GameConstants.spawnOffsetX,
      facing: Facing.left,
    );
    timerTicks = _nextRoundSeconds * 60;
    hitstopTicks = 0;
    ghostP1 = 1;
    ghostP2 = 1;
    projectiles.clear();
    comboOnP1.reset();
    comboOnP2.reset();
    comboPopupOnP1 = 0;
    comboPopupOnP2 = 0;
    _roundWinnerId = null;
    onTimeScale?.call(1.0);
  }

  void _resolvePush() {
    final resolution = PushResolver.resolve(
      bodyA: p1.worldBodyBox(),
      bodyB: p2.worldBodyBox(),
      minXA: p1.minX,
      maxXA: p1.maxX,
      minXB: p2.minX,
      maxXB: p2.maxX,
      xA: p1.logicX,
      xB: p2.logicX,
    );
    p1.logicX += resolution.deltaA;
    p2.logicX += resolution.deltaB;
  }

  void _resolveHits() {
    // Both directions evaluated against pre-application state so trades
    // land on the same tick.
    final viewP1 = p1.buildCombatView();
    final viewP2 = p2.buildCombatView();
    final hitOnP2 =
        CollisionResolver.checkHit(attacker: viewP1, defender: viewP2);
    final hitOnP1 =
        CollisionResolver.checkHit(attacker: viewP2, defender: viewP1);
    if (hitOnP2 != null) _applyHit(attacker: p1, defender: p2, event: hitOnP2);
    if (hitOnP1 != null) _applyHit(attacker: p2, defender: p1, event: hitOnP1);
  }

  void _applyHit({
    required FighterComponent attacker,
    required FighterComponent defender,
    required HitEvent event,
    bool fromProjectile = false,
  }) {
    if (!fromProjectile) attacker.fsm.notifyConnected();

    // Combo bookkeeping and damage scaling (unblocked hits only).
    var damage = event.damage;
    if (!event.blocked) {
      final combo = identical(defender, p1) ? comboOnP1 : comboOnP2;
      final continuing = defender.fsm.state.isStunned;
      if (!continuing) combo.reset();
      damage = (event.damage * combo.nextHitScale).round();
      combo.registerHit();
      if (identical(defender, p1)) {
        comboPopupOnP1 = combo.hits;
        comboPopupTickOnP1 = totalTicks;
      } else {
        comboPopupOnP2 = combo.hits;
        comboPopupTickOnP2 = totalTicks;
      }
    }

    defender.applyHit(event, damageOverride: damage);
    attacker.meter.add(event.meterGain);
    defender.meter.add(damage ~/ 2);

    // Corner transfer: a walled defender passes the pushback to the attacker.
    if (event.pushback != 0 && defender.atBound(event.pushback.sign)) {
      attacker.startSlide(-event.pushback);
    }
    hitstopTicks = math.max(hitstopTicks, event.hitstopTicks);
    if (identical(defender, p1)) {
      lastHitTickP1 = totalTicks;
    } else {
      lastHitTickP2 = totalTicks;
    }
    onHitFeedback?.call(event);
  }

  void _collectProjectiles() {
    final fromP1 = p1.takeProjectileRequest();
    if (fromP1 != null) projectiles.add(fromP1);
    final fromP2 = p2.takeProjectileRequest();
    if (fromP2 != null) projectiles.add(fromP2);
  }

  void _tickProjectiles() {
    for (final projectile in projectiles) {
      projectile.tick();
      if (projectile.done) continue;
      final owner = projectile.ownerId == p1.playerId ? p1 : p2;
      final defender = identical(owner, p1) ? p2 : p1;
      final event = projectile.checkHit(defender.buildCombatView());
      if (event != null) {
        projectile.done = true;
        _applyHit(
          attacker: owner,
          defender: defender,
          event: event,
          fromProjectile: true,
        );
      }
    }
    projectiles.removeWhere((p) => p.done);
  }

  void _updateFacing() {
    if (!p1.grounded || !p2.grounded) return;
    if (p1.fsm.state.isNeutral) {
      p1.fsm.facing = Facing.towards(p1.logicX, p2.logicX, p1.fsm.facing);
    }
    if (p2.fsm.state.isNeutral) {
      p2.fsm.facing = Facing.towards(p2.logicX, p1.logicX, p2.fsm.facing);
    }
  }

  void _updateGhostBars() {
    // Ghost bar drains a full bar in ~30 ticks, after a short hang.
    const drainPerTick = 1 / 30;
    if (totalTicks - lastHitTickP1 > 12) {
      ghostP1 = MathUtils.approach(ghostP1, p1.health.fraction, drainPerTick);
    }
    ghostP1 = math.max(ghostP1, p1.health.fraction);
    if (totalTicks - lastHitTickP2 > 12) {
      ghostP2 = MathUtils.approach(ghostP2, p2.health.fraction, drainPerTick);
    }
    ghostP2 = math.max(ghostP2, p2.health.fraction);
  }
}
