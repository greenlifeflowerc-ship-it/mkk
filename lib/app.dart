import 'package:flutter/material.dart';

import 'ui/screens/title_screen.dart';
import 'ui/theme/ui_theme.dart';

/// Application shell: title -> main menu -> fighter select -> stage select
/// -> fight, all via standard navigation.
class IronOmenApp extends StatelessWidget {
  const IronOmenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRON OMEN',
      debugShowCheckedModeBanner: false,
      theme: UiTheme.materialTheme(),
      home: const TitleScreen(),
    );
  }
}
