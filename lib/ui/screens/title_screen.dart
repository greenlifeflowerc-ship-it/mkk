import 'package:flutter/material.dart';

import '../theme/ui_theme.dart';
import 'main_menu_screen.dart';

/// Boot screen: logo plate over the dark-arcade backdrop; any tap or key
/// continues to the main menu.
class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  void _continue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MainMenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiTheme.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _continue(context),
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            _continue(context);
            return KeyEventResult.handled;
          },
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'IRON',
                  style: TextStyle(
                    color: UiTheme.boneWhite,
                    fontSize: 110,
                    height: 0.9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 28,
                    shadows: [
                      Shadow(color: UiTheme.bloodRed, blurRadius: 34),
                    ],
                  ),
                ),
                Text(
                  'OMEN',
                  style: TextStyle(
                    color: UiTheme.bloodRed,
                    fontSize: 110,
                    height: 0.9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 28,
                    shadows: [
                      Shadow(color: UiTheme.emberOrange, blurRadius: 40),
                    ],
                  ),
                ),
                SizedBox(height: 60),
                Text(
                  'PRESS ANY KEY / TAP',
                  style: TextStyle(
                    color: UiTheme.metalGrey,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
