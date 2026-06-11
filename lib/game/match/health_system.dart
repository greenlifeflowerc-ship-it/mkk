import '../../core/constants/game_constants.dart';

/// Hit points for one fighter within a round.
class HealthSystem {
  HealthSystem({this.maxHealth = GameConstants.maxHealth})
      : current = maxHealth;

  final int maxHealth;
  int current;

  /// Applies [amount] damage. Chip damage passes `canKo: false` and always
  /// leaves at least 1 HP.
  void applyDamage(int amount, {bool canKo = true}) {
    current -= amount;
    if (!canKo && current <= 0) current = 1;
    if (current < 0) current = 0;
  }

  bool get isKo => current <= 0;

  double get fraction => maxHealth == 0 ? 0 : current / maxHealth;

  void reset() => current = maxHealth;
}
