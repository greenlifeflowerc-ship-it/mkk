import 'dart:ui'
    show BlendMode, Canvas, Color, ColorFilter, FilterQuality, Paint;

import 'package:flame/components.dart';

import '../../core/constants/game_constants.dart';
import '../../core/utils/math_utils.dart';
import '../combat/collision_resolver.dart';
import '../combat/frame_data.dart';
import '../combat/hit_event.dart';
import '../combat/move_data.dart';
import '../combat/projectile.dart';
import '../input/input_buffer.dart';
import '../input/input_controller.dart';
import '../input/input_snapshot.dart';
import '../match/health_system.dart';
import '../match/meter_system.dart';
import 'combat_state_machine.dart';
import 'facing.dart';
import 'fighter_animation_manager.dart';
import 'fighter_data.dart';
import 'fighter_state.dart';

/// One fighter in the world. Owns its state machine, input buffer, health
/// and physics. Logic advances only in [logicTick] (fixed 60 Hz); [update]
/// merely interpolates the rendered position between the last two states.
class FighterComponent extends PositionComponent {
  FighterComponent({
    required this.playerId,
    required this.data,
    required this.animations,
    required this.controller,
    required Facing initialFacing,
    required double startX,
    required this.interpolationAlpha,
  })  : fsm = CombatStateMachine(data, facing: initialFacing),
        health = HealthSystem(maxHealth: data.maxHealth),
        logicX = startX,
        prevX = startX,
        logicY = GameConstants.floorY,
        prevY = GameConstants.floorY;

  final String playerId;
  final FighterData data;
  final FighterAnimationManager animations;
  final InputController controller;
  final CombatStateMachine fsm;
  final HealthSystem health;
  final MeterSystem meter = MeterSystem();
  final InputBuffer buffer = InputBuffer();

  // One projectile per move activation; the match layer collects requests.
  MoveData? _projectileFiredForMove;
  ActiveProjectile? _pendingProjectile;

  /// Render interpolation fraction provided by the game's ticker.
  final double Function() interpolationAlpha;

  // Logic-space physics state.
  double logicX;
  double logicY;
  double prevX;
  double prevY;
  double velocityX = 0;
  double velocityY = 0;
  bool grounded = true;

  // Pushback slide, spread over a few ticks for readable motion.
  static const int _slideTicks = 6;
  int _slideTicksRemaining = 0;
  double _slideVelocityX = 0;

  /// Walkable range for this fighter's center, body width accounted for.
  double get minX => GameConstants.stageLeftBound + data.bodyBox.width / 2;
  double get maxX => GameConstants.stageRightBound - data.bodyBox.width / 2;

  /// Crisp nearest-neighbor upscaling for pixel art.
  static final Paint _spritePaint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  /// White impact flash drawn over the sprite on the first hitstun ticks.
  static final Paint _flashPaint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false
    ..colorFilter =
        const ColorFilter.mode(Color(0xB8FFFFFF), BlendMode.srcATop);

  @override
  Future<void> onLoad() async {
    size = Vector2.all(data.frameSize * data.renderScale);
    anchor = Anchor(0.5, data.spriteFeetY / data.frameSize);
    position.setValues(logicX, logicY);
  }

  /// Advances one fixed logic tick. Position corrections from push/hit
  /// resolution happen afterwards at the match level, before rendering.
  /// With [acceptInput] false (round intro/end) the controller is still
  /// sampled — keeping edge detection warm — but the fighter sees no input.
  void logicTick(int tick, {bool acceptInput = true}) {
    prevX = logicX;
    prevY = logicY;

    var snapshot = controller.sample();
    if (!acceptInput) snapshot = InputSnapshot.empty;
    buffer.push(snapshot, tick);
    fsm.meterBars = meter.bars;
    fsm.tick(snapshot, buffer);
    if (fsm.pendingMeterSpend) {
      meter.trySpendBar();
      fsm.pendingMeterSpend = false;
    }
    _checkProjectileSpawn();

    const dt = GameConstants.tickSeconds;
    if (fsm.motion.startJump) {
      velocityY = GameConstants.jumpVelocityY;
      velocityX = fsm.motion.jumpVelocityX * GameConstants.jumpVelocityX;
      grounded = false;
    } else if (grounded) {
      velocityX = fsm.motion.velocityX;
    }
    if (!grounded) {
      velocityY += GameConstants.gravity * dt;
    }

    logicX += velocityX * dt;
    logicY += velocityY * dt;

    if (_slideTicksRemaining > 0) {
      logicX += _slideVelocityX * dt;
      _slideTicksRemaining--;
    }

    if (!grounded && logicY >= GameConstants.floorY && velocityY >= 0) {
      logicY = GameConstants.floorY;
      velocityY = 0;
      velocityX = 0;
      grounded = true;
      fsm.onLanded();
    }
    logicX = MathUtils.clampDouble(logicX, minX, maxX);
  }

  /// Applies an incoming hit: damage, state change, launch and pushback.
  /// [damageOverride] carries combo-scaled damage from the match layer.
  void applyHit(HitEvent event, {int? damageOverride}) {
    health.applyDamage(damageOverride ?? event.damage, canKo: !event.blocked);
    fsm.receiveHit(event, airborne: !grounded);

    if (!event.blocked && (event.knockbackX != 0 || event.knockbackY != 0)) {
      velocityX = event.knockbackX;
      velocityY = event.knockbackY;
      grounded = false;
      logicY -= 1; // Leave the floor so landing detection re-arms.
    } else if (event.pushback != 0) {
      startSlide(event.pushback);
    }

    if (health.isKo) {
      fsm.koFlag = true;
      if (grounded && !fsm.state.isAirborne &&
          fsm.state != FighterState.knockdown) {
        fsm.forceState(FighterState.knockdown);
      }
    }
  }

  void _checkProjectileSpawn() {
    final move = fsm.currentMove;
    // A fresh activation (tick 0) re-arms the one-shot latch; MoveData
    // instances are shared between activations.
    if (fsm.stateTick == 0) _projectileFiredForMove = null;
    if (move == null || move.projectile == null) return;
    if (fsm.stateTick != move.projectileSpawnTick) return;
    if (identical(_projectileFiredForMove, move)) return;
    _projectileFiredForMove = move;
    final p = move.projectile!;
    _pendingProjectile = ActiveProjectile(
      ownerId: playerId,
      fighterId: data.id,
      sourceMove: move,
      data: p,
      direction: fsm.facing.sign,
      x: logicX + p.spawnOffsetX * fsm.facing.sign,
      y: logicY + p.spawnOffsetY,
    );
  }

  /// Returns and clears the projectile spawned this tick, if any.
  ActiveProjectile? takeProjectileRequest() {
    final p = _pendingProjectile;
    _pendingProjectile = null;
    return p;
  }

  /// Resets everything round-scoped: position, physics, health, input
  /// buffer and state machine. Meter persists across rounds (§3.8).
  void resetForRound({required double startX, required Facing facing}) {
    logicX = prevX = startX;
    logicY = prevY = GameConstants.floorY;
    velocityX = 0;
    velocityY = 0;
    grounded = true;
    _slideTicksRemaining = 0;
    _slideVelocityX = 0;
    health.reset();
    buffer.clear();
    fsm.resetForRound(facing);
  }

  /// Slides the fighter [totalPx] (signed, world space) over a few ticks.
  void startSlide(double totalPx) {
    _slideTicksRemaining = _slideTicks;
    _slideVelocityX = totalPx / (_slideTicks * GameConstants.tickSeconds);
  }

  /// True when pushed against the wall in the given direction (+1 right).
  bool atBound(double direction) =>
      direction > 0 ? logicX >= maxX - 1 : logicX <= minX + 1;

  bool get facingRight => fsm.facing == Facing.right;

  CombatBox worldBodyBox() =>
      data.bodyBox.toWorld(logicX, logicY, facingRight: facingRight);

  /// Immutable view of this fighter for the collision resolver.
  CombatantView buildCombatView() {
    final move = fsm.currentMove;
    return CombatantView(
      id: playerId,
      x: logicX,
      y: logicY,
      facingRight: facingRight,
      move: move,
      moveTick: fsm.stateTick,
      moveHasConnected: fsm.moveHasConnected,
      hurtboxes: [
        ...data.hurtboxesForState(fsm.state),
        ...?move?.hurtboxesAt(fsm.stateTick),
      ],
      invulnerable: fsm.isInvulnerable,
      airborne: !grounded,
      blockingHigh: fsm.state == FighterState.blockHigh,
      blockingLow: fsm.state == FighterState.blockLow,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final alpha = interpolationAlpha();
    position.setValues(
      MathUtils.lerp(prevX, logicX, alpha),
      MathUtils.lerp(prevY, logicY, alpha),
    );
    scale.x = fsm.facing.sign;
  }

  @override
  void render(Canvas canvas) {
    final sprite =
        animations.spriteFor(fsm.state, fsm.stateTick, fsm.currentMove);
    final flashing = (fsm.state == FighterState.hitstun ||
            fsm.state == FighterState.crouchHitstun ||
            fsm.state == FighterState.airHit) &&
        fsm.stateTick < 3;
    sprite.render(canvas,
        size: size, overridePaint: flashing ? _flashPaint : _spritePaint);
  }
}
