/// Which way a fighter is looking. Sprites are authored facing right and
/// flipped via `scale.x = -1`; combat boxes are mirrored at resolution time.
enum Facing {
  right,
  left;

  double get sign => this == Facing.right ? 1 : -1;

  Facing get flipped => this == Facing.right ? Facing.left : Facing.right;

  /// Facing that points from [fromX] towards [toX]; keeps the current value
  /// when the two are exactly aligned.
  static Facing towards(double fromX, double toX, Facing current) {
    if (toX > fromX) return Facing.right;
    if (toX < fromX) return Facing.left;
    return current;
  }
}
