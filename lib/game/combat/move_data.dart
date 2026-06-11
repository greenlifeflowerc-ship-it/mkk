import '../../core/constants/game_constants.dart';
import 'frame_data.dart';
import 'projectile.dart';

/// Guard level of an attack: determines which block stance defends it.
/// - high: blocked standing only
/// - mid: blocked standing or crouching
/// - low: blocked crouching only
/// - overhead: blocked standing only (hits crouch-blockers)
enum HitLevel { high, mid, low, overhead }

/// Strength class of a move; drives hitstop duration and SFX choice.
enum MoveStrength { light, heavy, special }

/// A window during a move in which it may be cancelled into another move.
class CancelRule {
  const CancelRule({
    required this.targetMoveId,
    required this.fromTick,
    required this.toTick,
    this.requiresContact = false,
  }) : assert(fromTick <= toTick);

  final String targetMoveId;

  /// Inclusive tick range (ticks since move start) in which the cancel is
  /// legal.
  final int fromTick;
  final int toTick;

  /// When true the cancel is only allowed after the move has connected
  /// (hit or block).
  final bool requiresContact;

  bool isOpenAt(int moveTick, {required bool hasConnected}) =>
      moveTick >= fromTick &&
      moveTick <= toTick &&
      (!requiresContact || hasConnected);
}

/// Immutable definition of a single attack. All timings are in 60 Hz ticks.
class MoveData {
  const MoveData({
    required this.id,
    required this.animation,
    required this.animStartFrame,
    required this.animEndFrame,
    required this.startup,
    required this.active,
    required this.recovery,
    required this.damage,
    required this.hitstun,
    required this.blockstun,
    required this.pushbackHit,
    required this.pushbackBlock,
    required this.strength,
    this.knockbackX = 0,
    this.knockbackY = 0,
    this.knocksDown = false,
    this.level = HitLevel.mid,
    this.meterGainOnHit = 0,
    this.meterGainOnBlock = 0,
    this.boxesPerTick = const [],
    this.cancelInto = const [],
    this.inputBufferLeniency = GameConstants.defaultInputLeniencyTicks,
    this.projectile,
    this.projectileSpawnTick = -1,
  })  : assert(startup >= 0),
        assert(active > 0),
        assert(recovery >= 0);

  final String id;

  /// Animation sheet key plus the inclusive frame range this move plays.
  final String animation;
  final int animStartFrame;
  final int animEndFrame;

  /// Phase durations in ticks. Ticks [0, startup) are startup, then
  /// [startup, startup + active) are active, then recovery.
  final int startup;
  final int active;
  final int recovery;

  final int damage;
  final int hitstun;
  final int blockstun;

  /// Horizontal push applied to the defender (logical px, away from the
  /// attacker).
  final double pushbackHit;
  final double pushbackBlock;

  final MoveStrength strength;

  /// Launch velocity applied on hit for knockdown/launcher moves
  /// (logical px/s; +x is away from the attacker, -y is up).
  final double knockbackX;
  final double knockbackY;
  final bool knocksDown;

  final HitLevel level;
  final int meterGainOnHit;
  final int meterGainOnBlock;

  /// One entry per active tick; entry i applies on tick `startup + i`.
  /// Empty hitbox lists inside an entry are legal (gap in a multi-hit move).
  final List<FrameBoxes> boxesPerTick;

  final List<CancelRule> cancelInto;
  final int inputBufferLeniency;

  /// Projectile fired by this move (if any) and the move tick it appears.
  final ProjectileData? projectile;
  final int projectileSpawnTick;

  int get totalTicks => startup + active + recovery;

  bool isActiveAt(int moveTick) =>
      moveTick >= startup && moveTick < startup + active;

  /// Hitboxes live at [moveTick], already validated to the active window.
  List<CombatBox> hitboxesAt(int moveTick) {
    if (!isActiveAt(moveTick) || boxesPerTick.isEmpty) return const [];
    final index = (moveTick - startup).clamp(0, boxesPerTick.length - 1);
    return boxesPerTick[index].hitboxes;
  }

  /// Move-specific hurtboxes at [moveTick] (e.g. an extended limb); empty
  /// means "use the fighter's default stance hurtboxes".
  List<CombatBox> hurtboxesAt(int moveTick) {
    if (!isActiveAt(moveTick) || boxesPerTick.isEmpty) return const [];
    final index = (moveTick - startup).clamp(0, boxesPerTick.length - 1);
    return boxesPerTick[index].hurtboxes;
  }

  int get hitstopTicks => switch (strength) {
        MoveStrength.light => GameConstants.hitstopLightTicks,
        MoveStrength.heavy => GameConstants.hitstopHeavyTicks,
        MoveStrength.special => GameConstants.hitstopSpecialTicks,
      };
}
