import '../combat/frame_data.dart';
import '../combat/move_data.dart';
import 'fighter_state.dart';

/// Definition of one animation sprite sheet: a horizontal strip of equal
/// 512x512 cells.
class FighterAnimationDef {
  const FighterAnimationDef({
    required this.key,
    required this.frameCount,
    this.loop = false,
    this.holdLast = false,
    this.ticksPerFrame = 4,
  }) : assert(frameCount > 0);

  /// File name stem; resolves to `assets/images/fighters/<id>/<key>.png`.
  final String key;
  final int frameCount;
  final bool loop;

  /// Non-looping animation that freezes on its last frame (crouch, blocks).
  final bool holdLast;

  /// Playback speed for non-attack animations. Attack animations are paced
  /// by their move's startup/active/recovery instead.
  final int ticksPerFrame;

  int get totalTicks => frameCount * ticksPerFrame;
}

/// Complete data-driven definition of a fighter: stats, stance boxes,
/// animation table and move list. Adding a new fighter means writing one of
/// these plus assets — zero engine changes.
class FighterData {
  const FighterData({
    required this.id,
    required this.displayName,
    required this.maxHealth,
    required this.walkForwardSpeed,
    required this.walkBackwardSpeed,
    required this.bodyBox,
    required this.standingHurtboxes,
    required this.crouchingHurtboxes,
    required this.airborneHurtboxes,
    required this.animations,
    required this.stateAnimation,
    required this.moves,
    required this.lightStarterMoveId,
    required this.heavyStarterMoveId,
    this.specialMoveId,
    this.specialExMoveId,
    this.uppercutMoveId,
    this.frameSize = 512,
    this.spriteFeetY = 500,
    this.renderScale = 1.0,
  });

  final String id;
  final String displayName;

  final int maxHealth;
  final double walkForwardSpeed;
  final double walkBackwardSpeed;

  /// Solid body box (fighter-local) used for push resolution.
  final CombatBox bodyBox;

  /// Default vulnerable boxes per stance; a move's own hurtboxes override
  /// these while it is active.
  final List<CombatBox> standingHurtboxes;
  final List<CombatBox> crouchingHurtboxes;
  final List<CombatBox> airborneHurtboxes;

  /// Animation definitions by key.
  final Map<String, FighterAnimationDef> animations;

  /// Which animation each state plays. Attack states are excluded — the
  /// current move names its own animation.
  final Map<FighterState, String> stateAnimation;

  final Map<String, MoveData> moves;

  /// Moves started by a raw light / heavy press from neutral.
  final String lightStarterMoveId;
  final String heavyStarterMoveId;

  /// Special move started by the SPECIAL button or a quarter-circle-forward
  /// + punch, and its EX upgrade used automatically when a meter bar is
  /// available. Null = fighter has no special yet.
  final String? specialMoveId;
  final String? specialExMoveId;

  /// Launcher started with down + heavy (standing or crouched).
  final String? uppercutMoveId;

  /// Square cell size of this fighter's sprite sheets, in source pixels.
  final double frameSize;

  /// Row in the source frame where the feet rest; the renderer aligns this
  /// row with the fighter's world position.
  final double spriteFeetY;

  /// Logical pixels per source pixel. Combat boxes are authored in logical
  /// space and are unaffected; this scales rendering only.
  final double renderScale;

  MoveData moveById(String id) {
    final move = moves[id];
    if (move == null) {
      throw ArgumentError('Fighter $id has no move "$id"');
    }
    return move;
  }

  FighterAnimationDef animationByKey(String key) {
    final def = animations[key];
    if (def == null) {
      throw ArgumentError('Fighter $id has no animation "$key"');
    }
    return def;
  }

  List<CombatBox> hurtboxesForState(FighterState state) {
    if (state.isAirborne) return airborneHurtboxes;
    if (state.isCrouching) return crouchingHurtboxes;
    return standingHurtboxes;
  }
}
