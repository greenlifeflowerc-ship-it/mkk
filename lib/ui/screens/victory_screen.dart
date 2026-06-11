import 'package:flutter/material.dart';

import '../theme/ui_theme.dart';
import 'pause_overlay.dart' show MenuActionButton, MetalPanel;

/// Match-end overlay: winner callout plus rematch. Returns to the main menu
/// once that exists (Phase 8).
class VictoryScreen extends StatelessWidget {
  const VictoryScreen({
    super.key,
    required this.winnerLabel,
    required this.onRematch,
    required this.onMainMenu,
  });

  final String winnerLabel;
  final VoidCallback onRematch;
  final VoidCallback onMainMenu;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xCC0A0A0C),
      child: Center(
        child: MetalPanel(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              winnerLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: UiTheme.bloodRed,
                fontSize: 64,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                shadows: [
                  Shadow(color: UiTheme.emberOrange, blurRadius: 30),
                ],
              ),
            ),
            const SizedBox(height: 40),
            MenuActionButton(label: 'REMATCH', onPressed: onRematch),
            const SizedBox(height: 14),
            MenuActionButton(label: 'MAIN MENU', onPressed: onMainMenu),
          ],
          ),
        ),
      ),
    );
  }
}
