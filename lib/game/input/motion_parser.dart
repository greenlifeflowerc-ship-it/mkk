import '../fighter/facing.dart';
import 'input_snapshot.dart';

/// Detects special-move motion commands in the recent input history.
/// History is oldest-first and spans the motion window (18 ticks).
class MotionParser {
  MotionParser._();

  /// Quarter-circle forward: down, then down-forward, then (optionally pure)
  /// forward — lenient like 90s arcades: reaching the diagonal is enough.
  static bool hasQuarterCircleForward(
      List<InputSnapshot> history, Facing facing) {
    var stage = 0;
    for (final s in history) {
      final forward = facing == Facing.right ? s.right : s.left;
      switch (stage) {
        case 0:
          if (s.down && !forward) stage = 1;
        case 1:
          if (s.down && forward) stage = 2;
        case 2:
          if (forward && !s.down) stage = 3;
      }
    }
    return stage >= 2;
  }
}
