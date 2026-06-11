import '../ai/cpu_brain.dart';

/// How a match is played: against the CPU, another human, or a dummy.
enum GameMode { arcade, versus, training }

extension GameModeLabel on GameMode {
  String get label => switch (this) {
        GameMode.arcade => 'ARCADE',
        GameMode.versus => 'VS MODE',
        GameMode.training => 'TRAINING',
      };
}

/// Everything the fight screen needs to start a match.
class MatchConfig {
  const MatchConfig({
    required this.mode,
    required this.p1FighterId,
    required this.p2FighterId,
    required this.stageId,
    this.difficulty = CpuDifficulty.normal,
  });

  final GameMode mode;
  final String p1FighterId;
  final String p2FighterId;
  final String stageId;
  final CpuDifficulty difficulty;
}
