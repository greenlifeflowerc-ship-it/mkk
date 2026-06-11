import 'package:flutter/material.dart';

import '../../data/stages/stage_registry.dart';
import '../../game/ai/cpu_brain.dart';
import '../../game/match/match_config.dart';
import '../theme/ui_theme.dart';
import 'fight_screen.dart';

/// Stage strip: pick the arena, then fight.
class StageSelectScreen extends StatelessWidget {
  const StageSelectScreen({
    super.key,
    required this.mode,
    required this.p1FighterId,
    required this.p2FighterId,
    required this.difficulty,
  });

  final GameMode mode;
  final String p1FighterId;
  final String p2FighterId;
  final CpuDifficulty difficulty;

  void _start(BuildContext context, String stageId) {
    final config = MatchConfig(
      mode: mode,
      p1FighterId: p1FighterId,
      p2FighterId: p2FighterId,
      stageId: stageId,
      difficulty: difficulty,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => FightScreen(config: config)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            const Text(
              'CHOOSE THE ARENA',
              style: TextStyle(
                color: UiTheme.boneWhite,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
              ),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final id in stageIds)
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: _StageTile(
                          stageId: id,
                          onTap: () => _start(context, id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({required this.stageId, required this.onTap});

  final String stageId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stage = stageDataById(stageId);
    String? firstImage;
    for (final layer in stage.layers) {
      if (layer.file != null) {
        firstImage = layer.file;
        break;
      }
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 320,
        height: 220,
        decoration: BoxDecoration(
          color: UiTheme.metalDark,
          border: Border.all(color: UiTheme.metalGrey, width: 3),
        ),
        child: Column(
          children: [
            Expanded(
              child: firstImage != null
                  ? Image.asset(
                      'assets/images/$firstImage',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.none,
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            stage.layers.first.colors.first,
                            stage.layers.first.colors.last,
                            UiTheme.bloodRed.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
            ),
            Container(
              width: double.infinity,
              color: UiTheme.metalGrey,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                stage.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: UiTheme.boneWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
