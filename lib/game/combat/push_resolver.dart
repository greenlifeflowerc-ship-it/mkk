import 'dart:math' as math;

import 'frame_data.dart';

/// Positional corrections for two overlapping bodies, in world px.
class PushResolution {
  const PushResolution(this.deltaA, this.deltaB);

  static const PushResolution none = PushResolution(0, 0);

  final double deltaA;
  final double deltaB;
}

/// Separates overlapping fighter body boxes. Normally each fighter takes
/// half the correction; a cornered fighter transfers the remainder to the
/// other, so bodies never tunnel through walls.
class PushResolver {
  PushResolver._();

  static PushResolution resolve({
    required CombatBox bodyA,
    required CombatBox bodyB,
    required double minXA,
    required double maxXA,
    required double minXB,
    required double maxXB,
    required double xA,
    required double xB,
  }) {
    final overlap = math.min(bodyA.right, bodyB.right) -
        math.max(bodyA.left, bodyB.left);
    if (overlap <= 0 ||
        bodyA.bottom <= bodyB.top ||
        bodyB.bottom <= bodyA.top) {
      return PushResolution.none;
    }

    // A is pushed towards its own side; exact overlaps break right.
    final centerA = bodyA.left + bodyA.width / 2;
    final centerB = bodyB.left + bodyB.width / 2;
    final aOnLeft = centerA == centerB ? xA <= xB : centerA < centerB;

    final half = overlap / 2;
    var deltaA = aOnLeft ? -half : half;
    var deltaB = aOnLeft ? half : -half;

    // Corner handling: clamp each delta to the room its fighter has, and
    // hand the shortfall to the other fighter.
    final roomA = aOnLeft ? xA - minXA : maxXA - xA;
    final roomB = aOnLeft ? maxXB - xB : xB - minXB;

    if (deltaA.abs() > roomA) {
      final shortfall = deltaA.abs() - roomA;
      deltaA = aOnLeft ? -roomA : roomA;
      deltaB += aOnLeft ? shortfall : -shortfall;
    }
    if (deltaB.abs() > roomB) {
      final shortfall = deltaB.abs() - roomB;
      deltaB = aOnLeft ? roomB : -roomB;
      final extraA = deltaA.abs() + shortfall;
      deltaA = (aOnLeft ? -1 : 1) * math.min(extraA, roomA);
    }
    return PushResolution(deltaA, deltaB);
  }
}
