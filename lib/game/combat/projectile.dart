import '../../core/constants/game_constants.dart';
import 'collision_resolver.dart';
import 'frame_data.dart';
import 'hit_event.dart';
import 'move_data.dart';

/// Immutable definition of a projectile fired by a special move.
class ProjectileData {
  const ProjectileData({
    required this.speed,
    required this.damage,
    required this.hitstun,
    required this.blockstun,
    required this.pushback,
    this.knocksDown = false,
    this.level = HitLevel.mid,
    this.lifetimeTicks = 180,
    this.box = const CombatBox(x: -70, y: -60, width: 140, height: 120),
    this.spawnOffsetX = 170,
    this.spawnOffsetY = -300,
    this.renderSize = 200,
  });

  /// Travel speed in logical px/s, along the owner's facing.
  final double speed;
  final int damage;
  final int hitstun;
  final int blockstun;
  final double pushback;
  final bool knocksDown;
  final HitLevel level;
  final int lifetimeTicks;

  /// Hit volume local to the projectile center; +x = travel direction.
  final CombatBox box;

  /// Spawn point relative to the owner's feet (+x = facing).
  final double spawnOffsetX;
  final double spawnOffsetY;

  /// Square render size in logical px.
  final double renderSize;
}

/// A live projectile in the match. Pure logic state; rendering reads it.
class ActiveProjectile {
  ActiveProjectile({
    required this.ownerId,
    required this.fighterId,
    required this.sourceMove,
    required this.data,
    required this.direction,
    required this.x,
    required this.y,
  }) : prevX = x;

  final String ownerId;

  /// Fighter id used to look up the projectile sprite sheet.
  final String fighterId;

  /// The special move that spawned this projectile.
  final MoveData sourceMove;
  final ProjectileData data;

  /// +1 travelling right, -1 travelling left.
  final double direction;

  double x;
  double prevX;
  final double y;
  int ticksAlive = 0;
  bool done = false;

  bool get facingRight => direction > 0;

  /// Advances one logic tick; flags [done] past lifetime or stage margins.
  void tick() {
    prevX = x;
    x += data.speed * direction * GameConstants.tickSeconds;
    ticksAlive++;
    if (ticksAlive > data.lifetimeTicks ||
        x < GameConstants.stageLeftBound - 400 ||
        x > GameConstants.stageRightBound + 400) {
      done = true;
    }
  }

  /// Tests this projectile against [defender]; mirrors the melee block and
  /// chip rules (projectiles are always special-strength).
  HitEvent? checkHit(CombatantView defender) {
    if (done || defender.invulnerable) return null;
    final worldBox = data.box.toWorld(x, y, facingRight: facingRight);
    var connected = false;
    for (final hurt in defender.worldHurtboxes()) {
      if (worldBox.overlaps(hurt)) {
        connected = true;
        break;
      }
    }
    if (!connected) return null;

    final blocked = !defender.airborne &&
        CollisionResolver.blockCovers(
          data.level,
          blockingHigh: defender.blockingHigh,
          blockingLow: defender.blockingLow,
        );
    if (blocked) {
      return HitEvent(
        attackerId: ownerId,
        defenderId: defender.id,
        move: sourceMove,
        blocked: true,
        damage: (data.damage * GameConstants.chipDamageRatio).round(),
        stunTicks: data.blockstun,
        pushback: data.pushback * direction,
        knockbackX: 0,
        knockbackY: 0,
        knocksDown: false,
        hitstopTicks: GameConstants.hitstopSpecialTicks,
        meterGain: sourceMove.meterGainOnBlock,
        defenderWasAirborne: false,
      );
    }
    return HitEvent(
      attackerId: ownerId,
      defenderId: defender.id,
      move: sourceMove,
      blocked: false,
      damage: data.damage,
      stunTicks: data.hitstun,
      pushback: data.pushback * direction,
      knockbackX: data.knocksDown ? 420 * direction : 0,
      knockbackY: data.knocksDown ? -650 : 0,
      knocksDown: data.knocksDown || defender.airborne,
      hitstopTicks: GameConstants.hitstopSpecialTicks,
      meterGain: sourceMove.meterGainOnHit,
      defenderWasAirborne: defender.airborne,
    );
  }
}
