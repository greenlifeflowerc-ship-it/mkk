/// Small math helpers shared by gameplay and rendering code.
class MathUtils {
  MathUtils._();

  static double lerp(double a, double b, double t) => a + (b - a) * t;

  /// Moves [current] towards [target] by at most [maxDelta].
  static double approach(double current, double target, double maxDelta) {
    if ((target - current).abs() <= maxDelta) return target;
    return current + (target > current ? maxDelta : -maxDelta);
  }

  static double clampDouble(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
