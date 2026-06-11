import 'frame_data.dart';
import 'hit_event.dart';
import 'move_data.dart';

/// Snapshot of one fighter's combat-relevant state for a single tick.
/// Built by the match layer from live components; tests construct it
/// directly — the resolver itself is pure data + math.
class CombatantView {
  const CombatantView({
    required this.id,
    required this.x,
    required this.y,
    required this.facingRight,
    this.move,
    this.moveTick = 0,
    this.moveHasConnected = false,
    this.hurtboxes = const [],
    this.invulnerable = false,
    this.airborne = false,
    this.blockingHigh = false,
    this.blockingLow = false,
  });

  final String id;
  final double x;
  final double y;
  final bool facingRight;

  /// The move currently being performed, if any, and ticks since its start.
  final MoveData? move;
  final int moveTick;
  final bool moveHasConnected;

  /// Local-space vulnerable boxes (stance boxes plus any move-specific
  /// extended-limb boxes).
  final List<CombatBox> hurtboxes;

  final bool invulnerable;
  final bool airborne;
  final bool blockingHigh;
  final bool blockingLow;

  List<CombatBox> worldHurtboxes() => [
        for (final box in hurtboxes)
          box.toWorld(x, y, facingRight: facingRight),
      ];

  List<CombatBox> worldHitboxes() {
    final m = move;
    if (m == null) return const [];
    return [
      for (final box in m.hitboxesAt(moveTick))
        box.toWorld(x, y, facingRight: facingRight),
    ];
  }
}

/// Manual, deterministic combat collision. Runs inside the fixed tick —
/// never via engine collision callbacks.
class CollisionResolver {
  CollisionResolver._();

  /// Whether a block stance defends against an attack of [level].
  static bool blockCovers(HitLevel level,
      {required bool blockingHigh, required bool blockingLow}) {
    return switch (level) {
      HitLevel.high => blockingHigh,
      HitLevel.mid => blockingHigh || blockingLow,
      HitLevel.low => blockingLow,
      HitLevel.overhead => blockingHigh,
    };
  }

  /// Tests [attacker]'s active hitboxes against [defender]'s hurtboxes and
  /// produces the resulting [HitEvent], or null when nothing connects.
  /// Enforces one hit per move activation via [CombatantView.moveHasConnected].
  static HitEvent? checkHit({
    required CombatantView attacker,
    required CombatantView defender,
  }) {
    final move = attacker.move;
    if (move == null || attacker.moveHasConnected) return null;
    if (defender.invulnerable) return null;

    final hitboxes = attacker.worldHitboxes();
    if (hitboxes.isEmpty) return null;
    final hurtboxes = defender.worldHurtboxes();

    var connected = false;
    for (final hit in hitboxes) {
      for (final hurt in hurtboxes) {
        if (hit.overlaps(hurt)) {
          connected = true;
          break;
        }
      }
      if (connected) break;
    }
    if (!connected) return null;

    final blocked = !defender.airborne &&
        blockCovers(
          move.level,
          blockingHigh: defender.blockingHigh,
          blockingLow: defender.blockingLow,
        );

    final pushSign = attacker.facingRight ? 1.0 : -1.0;
    if (blocked) {
      final chip = move.strength == MoveStrength.special
          ? (move.damage * 0.15).round()
          : 0;
      return HitEvent(
        attackerId: attacker.id,
        defenderId: defender.id,
        move: move,
        blocked: true,
        damage: chip,
        stunTicks: move.blockstun,
        pushback: move.pushbackBlock * pushSign,
        knockbackX: 0,
        knockbackY: 0,
        knocksDown: false,
        hitstopTicks: move.hitstopTicks,
        meterGain: move.meterGainOnBlock,
        defenderWasAirborne: false,
      );
    }
    return HitEvent(
      attackerId: attacker.id,
      defenderId: defender.id,
      move: move,
      blocked: false,
      damage: move.damage,
      stunTicks: move.hitstun,
      pushback: move.pushbackHit * pushSign,
      knockbackX: move.knockbackX * pushSign,
      knockbackY: move.knockbackY,
      knocksDown: move.knocksDown || defender.airborne,
      hitstopTicks: move.hitstopTicks,
      meterGain: move.meterGainOnHit,
      defenderWasAirborne: defender.airborne,
    );
  }
}
