import 'move_data.dart';

/// Outcome of an attack connecting with a defender on a given tick. Produced
/// by the collision resolver, consumed by the match layer which applies
/// damage, stun, pushback and hitstop.
class HitEvent {
  const HitEvent({
    required this.attackerId,
    required this.defenderId,
    required this.move,
    required this.blocked,
    required this.damage,
    required this.stunTicks,
    required this.pushback,
    required this.knockbackX,
    required this.knockbackY,
    required this.knocksDown,
    required this.hitstopTicks,
    required this.meterGain,
    required this.defenderWasAirborne,
  });

  final String attackerId;
  final String defenderId;
  final MoveData move;

  /// True when the defender blocked at the correct level: stun is blockstun
  /// and damage is chip only.
  final bool blocked;

  final int damage;
  final int stunTicks;

  /// Horizontal pushback in logical px, signed in world space (positive =
  /// defender pushed right).
  final double pushback;

  /// Launch velocity in world space (px/s) for knockdown hits.
  final double knockbackX;
  final double knockbackY;
  final bool knocksDown;

  final int hitstopTicks;
  final int meterGain;
  final bool defenderWasAirborne;
}
