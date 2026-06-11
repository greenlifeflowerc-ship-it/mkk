/// Match flow phases (§3.8):
/// intro -> fighting -> koSlowmo -> roundEnd -> (next round | matchEnd).
enum RoundPhase { intro, fighting, koSlowmo, roundEnd, matchEnd }

/// Phase timings in ticks.
class RoundTiming {
  RoundTiming._();

  /// "ROUND N" hold.
  static const int announceRound = 45;

  /// "FIGHT!" hold before inputs unlock.
  static const int announceFight = 30;

  static const int introTotal = announceRound + announceFight;

  /// KO slow-motion duration.
  static const int koSlowmo = 90;

  /// Winner switches to victory pose this many ticks into the slow-mo.
  static const int victoryPoseDelay = 60;

  /// Hold on the round result before reset / match end.
  static const int roundEndHold = 120;

  /// Sudden-death timer after a draw, in seconds.
  static const int suddenDeathSeconds = 30;
}
