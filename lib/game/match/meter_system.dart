/// Super meter for one fighter: three segments, gained by dealing and
/// taking damage, spent one bar at a time on EX specials. Persists across
/// rounds; only a full rematch resets it.
class MeterSystem {
  static const int barValue = 300;
  static const int maxBars = 3;

  int value = 0;

  int get bars => value ~/ barValue;

  double get fraction => value / (barValue * maxBars);

  /// Fill fraction [0,1] of one displayed segment.
  double segmentFraction(int segment) {
    final inSegment = value - segment * barValue;
    return (inSegment / barValue).clamp(0.0, 1.0);
  }

  void add(int amount) {
    value = (value + amount).clamp(0, barValue * maxBars);
  }

  bool trySpendBar() {
    if (bars < 1) return false;
    value -= barValue;
    return true;
  }

  void reset() => value = 0;
}
