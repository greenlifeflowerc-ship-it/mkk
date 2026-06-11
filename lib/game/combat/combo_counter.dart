import '../../core/constants/game_constants.dart';

/// Counts consecutive hits landed on a defender who never returned to
/// neutral, and provides the damage-scaling factor for the next hit.
class ComboCounter {
  int hits = 0;

  /// Scaling applied to the next hit of the current combo: 100% for the
  /// first hit, then down the table to a hard floor.
  double get nextHitScale {
    final table = GameConstants.comboDamageScaling;
    if (hits < table.length) return table[hits];
    return GameConstants.comboDamageScalingFloor;
  }

  void registerHit() => hits++;

  void reset() => hits = 0;

  bool get isCombo => hits >= 2;
}
