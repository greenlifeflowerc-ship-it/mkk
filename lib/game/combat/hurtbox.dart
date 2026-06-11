import 'frame_data.dart';

/// A vulnerable box already transformed to world space. Built fresh each
/// tick by the collision resolver from the defender's stance or move data.
class Hurtbox {
  const Hurtbox({required this.worldBox});

  final CombatBox worldBox;
}
