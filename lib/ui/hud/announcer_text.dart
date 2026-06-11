import 'package:flutter/material.dart';

import '../theme/ui_theme.dart';

/// Big center-screen announcer callouts: "ROUND 1", "FIGHT!", "K.O.".
/// Scale-slams in on every text change.
class AnnouncerText extends StatelessWidget {
  const AnnouncerText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: Tween<double>(begin: 2.4, end: 1).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: text.isEmpty
          ? const SizedBox.shrink(key: ValueKey(''))
          : Text(
              text,
              key: ValueKey(text),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: text == 'K.O.' ? UiTheme.bloodRed : UiTheme.boneWhite,
                fontSize: text == 'K.O.' ? 110 : 72,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                shadows: const [
                  Shadow(
                    color: UiTheme.emberOrange,
                    offset: Offset(0, 0),
                    blurRadius: 26,
                  ),
                  Shadow(
                    color: Color(0xE6000000),
                    offset: Offset(0, 5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
    );
  }
}
