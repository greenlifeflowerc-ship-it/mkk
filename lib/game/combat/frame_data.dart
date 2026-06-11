/// Axis-aligned combat rectangle in fighter-local space: origin is the feet
/// center, +x points in the facing direction, +y points down (so a standing
/// box has a negative [y] reaching up from the floor).
class CombatBox {
  const CombatBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  })  : assert(width > 0),
        assert(height > 0);

  final double x;
  final double y;
  final double width;
  final double height;

  double get left => x;
  double get top => y;
  double get right => x + width;
  double get bottom => y + height;

  /// Transforms this local box to world space for a fighter standing at
  /// ([originX], [originY]). When facing left, the box mirrors around the
  /// origin's vertical axis.
  CombatBox toWorld(double originX, double originY, {required bool facingRight}) {
    final worldX = facingRight ? originX + x : originX - (x + width);
    return CombatBox(x: worldX, y: originY + y, width: width, height: height);
  }

  bool overlaps(CombatBox other) =>
      left < other.right &&
      other.left < right &&
      top < other.bottom &&
      other.top < bottom;

  @override
  String toString() => 'CombatBox($x, $y, ${width}x$height)';
}

/// Hit and hurt rectangles for one active tick of a move, in fighter-local
/// space. Mirroring for left-facing fighters happens in the collision
/// resolver, never in this data.
class FrameBoxes {
  const FrameBoxes({this.hurtboxes = const [], this.hitboxes = const []});

  final List<CombatBox> hurtboxes;
  final List<CombatBox> hitboxes;
}
