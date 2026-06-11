import 'package:flutter_test/flutter_test.dart';
import 'package:mkc/core/constants/game_constants.dart';
import 'package:mkc/data/fighters/ash_viper.dart';
import 'package:mkc/game/ai/dummy_brain.dart';
import 'package:mkc/game/fighter/facing.dart';
import 'package:mkc/game/fighter/fighter_animation_manager.dart';
import 'package:mkc/game/fighter/fighter_component.dart';
import 'package:mkc/game/match/match_manager.dart';
import 'package:mkc/game/match/round_state.dart';

/// Headless match harness: real fighters and match manager, no engine.
class _Harness {
  _Harness() {
    final data = ashViper();
    final animations = FighterAnimationManager(data);
    final center =
        (GameConstants.stageLeftBound + GameConstants.stageRightBound) / 2;
    p1 = FighterComponent(
      playerId: 'P1',
      data: data,
      animations: animations,
      controller: DummyBrain(),
      initialFacing: Facing.right,
      startX: center - GameConstants.spawnOffsetX,
      interpolationAlpha: () => 0,
    );
    p2 = FighterComponent(
      playerId: 'P2',
      data: data,
      animations: animations,
      controller: DummyBrain(),
      initialFacing: Facing.left,
      startX: center + GameConstants.spawnOffsetX,
      interpolationAlpha: () => 0,
    );
    match = MatchManager(
      p1: p1,
      p2: p2,
      onTimeScale: timeScales.add,
    );
  }

  late final FighterComponent p1;
  late final FighterComponent p2;
  late final MatchManager match;
  final List<double> timeScales = [];

  void tickN(int n) {
    for (var i = 0; i < n; i++) {
      match.tick();
    }
  }

  /// Runs the intro so the match is in the fighting phase.
  void enterFighting() {
    tickN(RoundTiming.introTotal + 1);
    expect(match.phase, RoundPhase.fighting);
  }

  /// KOs [loser] and advances through slow-mo and round end.
  void koAndFinishRound(FighterComponent loser) {
    loser.health.applyDamage(loser.health.maxHealth);
    match.tick(); // KO detected -> koSlowmo.
    expect(match.phase, RoundPhase.koSlowmo);
    tickN(RoundTiming.koSlowmo + 1);
    expect(match.phase, RoundPhase.roundEnd);
    tickN(RoundTiming.roundEndHold + 1);
  }
}

void main() {
  test('intro runs ROUND/FIGHT announcements then unlocks fighting', () {
    final h = _Harness();
    expect(h.match.phase, RoundPhase.intro);
    expect(h.match.announcerText, 'ROUND 1');
    h.tickN(RoundTiming.announceRound + 1);
    expect(h.match.announcerText, 'FIGHT!');
    h.tickN(RoundTiming.announceFight);
    expect(h.match.phase, RoundPhase.fighting);
    expect(h.match.inputsEnabled, isTrue);
  });

  test('timer counts down one second per 60 fighting ticks', () {
    final h = _Harness();
    h.enterFighting();
    final start = h.match.timerSeconds;
    h.tickN(60);
    expect(h.match.timerSeconds, start - 1);
  });

  test('KO triggers slow-mo, round win and reset for round 2', () {
    final h = _Harness();
    h.enterFighting();
    h.p2.health.applyDamage(400);
    h.koAndFinishRound(h.p2);

    expect(h.match.roundNumber, 2);
    expect(h.match.p1Wins, 1);
    expect(h.match.p2Wins, 0);
    expect(h.match.phase, RoundPhase.intro);
    // Slow-mo engaged then released.
    expect(h.timeScales, contains(GameConstants.koSlowmoRate));
    expect(h.timeScales.last, 1.0);
    // Round state fully reset.
    expect(h.p2.health.current, h.p2.health.maxHealth);
    expect(h.p1.health.current, h.p1.health.maxHealth);
    expect(h.match.timerSeconds, GameConstants.roundTimerSeconds);
    expect(h.p1.logicX, lessThan(h.p2.logicX));
  });

  test('best of three: two round wins end the match', () {
    final h = _Harness();
    h.enterFighting();
    h.koAndFinishRound(h.p2);
    h.enterFighting();
    h.koAndFinishRound(h.p2);
    expect(h.match.phase, RoundPhase.matchEnd);
    expect(h.match.matchWinnerId, 'P1');
  });

  test('timeout awards the round to the higher-HP fighter', () {
    final h = _Harness();
    h.enterFighting();
    h.p2.health.applyDamage(100);
    h.match.timerTicks = 1;
    h.match.tick();
    expect(h.match.phase, RoundPhase.koSlowmo);
    expect(h.match.announcerText, 'TIME');
    h.tickN(RoundTiming.koSlowmo + RoundTiming.roundEndHold + 2);
    expect(h.match.p1Wins, 1);
  });

  test('timeout tie is a draw: no pips, sudden-death timer next round', () {
    final h = _Harness();
    h.enterFighting();
    h.match.timerTicks = 1;
    h.match.tick();
    h.tickN(RoundTiming.koSlowmo + RoundTiming.roundEndHold + 2);
    expect(h.match.p1Wins, 0);
    expect(h.match.p2Wins, 0);
    expect(h.match.phase, RoundPhase.intro);
    expect(h.match.timerSeconds, RoundTiming.suddenDeathSeconds);
  });

  test('ghost health bar trails actual damage and then catches up', () {
    final h = _Harness();
    h.enterFighting();
    h.p2.health.applyDamage(300);
    h.match.lastHitTickP2 = h.match.totalTicks;
    h.match.tick();
    expect(h.match.ghostP2, greaterThan(h.p2.health.fraction));
    h.tickN(60);
    expect(h.match.ghostP2,
        moreOrLessEquals(h.p2.health.fraction, epsilon: 0.001));
  });

  test('meter persists across rounds but resets on rematch', () {
    final h = _Harness();
    h.enterFighting();
    h.p1.meter.add(500);
    h.koAndFinishRound(h.p2);
    expect(h.p1.meter.value, 500, reason: 'meter persists between rounds');
    h.match.restartMatch();
    expect(h.p1.meter.value, 0, reason: 'rematch resets meter');
  });

  test('restartMatch rewinds everything to round 1', () {
    final h = _Harness();
    h.enterFighting();
    h.koAndFinishRound(h.p2);
    h.match.restartMatch();
    expect(h.match.roundNumber, 1);
    expect(h.match.p1Wins, 0);
    expect(h.match.phase, RoundPhase.intro);
    expect(h.p1.health.current, h.p1.health.maxHealth);
  });
}
