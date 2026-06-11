import 'frame_data.dart';
import 'move_data.dart';

/// An attack box already transformed to world space, tagged with the move
/// that produced it. Built fresh each tick by the collision resolver.
class Hitbox {
  const Hitbox({required this.worldBox, required this.move});

  final CombatBox worldBox;
  final MoveData move;
}
