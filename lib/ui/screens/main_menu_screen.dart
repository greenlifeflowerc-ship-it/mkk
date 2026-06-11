import 'package:flutter/material.dart';

import '../../game/match/match_config.dart';
import '../theme/ui_theme.dart';
import 'fighter_select_screen.dart';
import 'pause_overlay.dart' show MenuActionButton;

/// Mode selection: ARCADE (vs CPU), VS MODE (two local players),
/// TRAINING (dummy). Options lands with the Phase 8 settings pass.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void _startMode(BuildContext context, GameMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FighterSelectScreen(mode: mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'IRON OMEN',
              style: TextStyle(
                color: UiTheme.boneWhite,
                fontSize: 54,
                fontWeight: FontWeight.w900,
                letterSpacing: 14,
                shadows: [Shadow(color: UiTheme.bloodRed, blurRadius: 26)],
              ),
            ),
            const SizedBox(height: 52),
            for (final mode in GameMode.values) ...[
              MenuActionButton(
                label: mode.label,
                onPressed: () => _startMode(context, mode),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}
