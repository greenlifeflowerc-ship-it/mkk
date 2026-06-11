import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../core/constants/game_constants.dart';
import '../core/utils/ticker.dart';
import '../data/fighters/roster.dart';
import '../data/stages/stage_registry.dart';
import 'ai/cpu_brain.dart';
import 'ai/dummy_brain.dart';
import 'camera/fight_camera.dart';
import 'combat/hit_event.dart';
import 'combat/move_data.dart';
import 'debug_combat_overlay.dart';
import 'effects_renderer.dart';
import 'fighter/facing.dart';
import 'fighter/fighter_animation_manager.dart';
import 'fighter/fighter_component.dart';
import 'fighter/fighter_state.dart';
import 'input/input_controller.dart';
import 'input/keyboard_input.dart';
import 'input/touch_input.dart';
import 'match/match_config.dart';
import 'match/match_manager.dart';
import 'match/round_state.dart';
import 'projectiles_renderer.dart';
import 'stage/stage_component.dart';

/// Root game: builds the world from a [MatchConfig] and drives the fixed
/// 60 Hz tick. All match and combat logic lives in [MatchManager]; this
/// class owns presentation concerns: camera, hit feedback, pause, debug.
class IronOmenGame extends FlameGame with KeyboardEvents {
  IronOmenGame({required this.config})
      : super(
          camera: CameraComponent.withFixedResolution(
            width: GameConstants.logicalWidth,
            height: GameConstants.logicalHeight,
          ),
        ) {
    ticker = GameTicker(_logicTick);
  }

  final MatchConfig config;

  late final GameTicker ticker;
  late final FightCamera fightCamera;
  late final MatchManager match;
  late final EffectsRenderer effects;

  final Set<LogicalKeyboardKey> pressedKeys = {};
  final TouchInputState touchState = TouchInputState();
  final DummyBrain dummyBrain = DummyBrain();
  late final CpuBrain cpuBrain = CpuBrain(difficulty: config.difficulty);

  late final FighterComponent p1;
  late final FighterComponent p2;
  List<FighterComponent> get fighters => [p1, p2];

  /// F1 toggles combat box drawing.
  bool debugCombat = false;

  /// HUD-observable pause flag. The ticker is frozen while paused; the
  /// match's own slow-mo scale is restored on resume.
  final ValueNotifier<bool> pauseNotifier = ValueNotifier(false);
  double _matchTimeScale = 1.0;

  @override
  Future<void> onLoad() async {
    final stage = stageDataById(config.stageId);
    fightCamera = FightCamera(camera);

    await world.add(StageComponent(stage: stage, cameraX: () => fightCamera.x));

    final p1Data = fighterDataById(config.p1FighterId);
    final p1Animations = FighterAnimationManager(p1Data);
    await p1Animations.load(images);
    final p2Data = fighterDataById(config.p2FighterId);
    final p2Animations = FighterAnimationManager(p2Data);
    await p2Animations.load(images);

    final stageCenter = (stage.leftBound + stage.rightBound) / 2;
    p1 = FighterComponent(
      playerId: 'P1',
      data: p1Data,
      animations: p1Animations,
      controller: MergedInput(
        KeyboardInput(KeyboardBindings.player1, pressedKeys),
        TouchInput(touchState),
      ),
      initialFacing: Facing.right,
      startX: stageCenter - GameConstants.spawnOffsetX,
      interpolationAlpha: () => ticker.interpolation,
    )..priority = 10;
    p2 = FighterComponent(
      playerId: 'P2',
      data: p2Data,
      animations: p2Animations,
      controller: _buildP2Controller(),
      initialFacing: Facing.left,
      startX: stageCenter + GameConstants.spawnOffsetX,
      interpolationAlpha: () => ticker.interpolation,
    )..priority = 10;
    _wireBrains();

    match = MatchManager(
      p1: p1,
      p2: p2,
      onHitFeedback: _onHitFeedback,
      onTimeScale: _onMatchTimeScale,
    );

    await world.addAll([p1, p2]);
    final projectileRenderer = ProjectilesRenderer()..priority = 20;
    await world.add(projectileRenderer);
    await projectileRenderer.loadFor(p1Data.id);
    await projectileRenderer.loadFor(p2Data.id);
    effects = EffectsRenderer()..priority = 30;
    await world.add(effects);
    await world.add(DebugCombatOverlay()..priority = 100);

    fightCamera.snapTo(stageCenter);

    if (kDebugMode) {
      await camera.viewport.add(FpsTextComponent(position: Vector2(12, 12)));
    }
  }

  InputController _buildP2Controller() {
    return switch (config.mode) {
      GameMode.arcade => cpuBrain,
      GameMode.versus => KeyboardInput(KeyboardBindings.player2, pressedKeys),
      GameMode.training => dummyBrain,
    };
  }

  void _wireBrains() {
    dummyBrain.opponentDirection = () => (p1.logicX - p2.logicX).sign;
    cpuBrain.distance = () => (p1.logicX - p2.logicX).abs();
    cpuBrain.directionSign = () => (p1.logicX - p2.logicX).sign;
    cpuBrain.opponentAirborne = () => !p1.grounded;
    cpuBrain.opponentThreatening = () {
      final move = p1.fsm.currentMove;
      if (move == null || !p1.fsm.state.isAttacking) return false;
      return p1.fsm.stateTick < move.startup + move.active;
    };
  }

  @override
  void update(double dt) {
    ticker.advance(dt);
    super.update(dt);
  }

  void _logicTick() {
    match.tick();
    fightCamera.followTick(
      x1: p1.logicX,
      x2: p2.logicX,
      highestY: math.min(p1.logicY, p2.logicY),
    );
  }

  void _onHitFeedback(HitEvent event) {
    final defender = event.defenderId == p1.playerId ? p1 : p2;
    // Impact point: defender's leading edge at chest height, with a small
    // deterministic jitter so repeated hits don't stack pixel-perfectly.
    final towardAttacker = event.pushback >= 0 ? -1.0 : 1.0;
    final impactX = defender.logicX + towardAttacker * 90;
    final impactY =
        defender.logicY - 300 - (match.totalTicks % 3) * 30;
    final flip = event.pushback < 0;

    if (event.blocked) {
      effects.spawn('block_spark', impactX, impactY, size: 230, flip: flip);
      return;
    }
    switch (event.move.strength) {
      case MoveStrength.light:
        effects.spawn('hit_spark', impactX, impactY, size: 250, flip: flip);
      case MoveStrength.heavy:
        effects.spawn('hit_spark', impactX, impactY, size: 340, flip: flip);
        effects.spawn('blood_burst', impactX, impactY - 40,
            size: 400, flip: flip);
      case MoveStrength.special:
        effects.spawn('hit_spark', impactX, impactY, size: 390, flip: flip);
        effects.spawn('blood_burst', impactX, impactY - 40,
            size: 460, flip: flip);
    }
    if (event.knocksDown) {
      effects.spawn('blood_burst', impactX + towardAttacker * -60,
          impactY - 120, size: 520, flip: !flip);
    }
    if (event.move.strength != MoveStrength.light || event.knocksDown) {
      fightCamera.shake(ticks: 6, amplitude: 4 + event.damage * 0.08);
    }
  }

  void _onMatchTimeScale(double scale) {
    _matchTimeScale = scale;
    if (!pauseNotifier.value) ticker.timeScale = scale;
  }

  void togglePause() {
    if (match.phase == RoundPhase.matchEnd) return;
    pauseNotifier.value = !pauseNotifier.value;
    ticker.timeScale = pauseNotifier.value ? 0 : _matchTimeScale;
  }

  /// Quit-match from the pause overlay: unpause and restart from round 1.
  void quitToRematch() {
    match.restartMatch();
    pauseNotifier.value = false;
    ticker.timeScale = _matchTimeScale;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    pressedKeys
      ..clear()
      ..addAll(keysPressed);
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f1) {
        debugCombat = !debugCombat;
      } else if (event.logicalKey == LogicalKeyboardKey.f2 &&
          config.mode == GameMode.training) {
        final modes = DummyMode.values;
        dummyBrain.mode = modes[(dummyBrain.mode.index + 1) % modes.length];
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        togglePause();
      }
    }
    return KeyEventResult.handled;
  }
}

