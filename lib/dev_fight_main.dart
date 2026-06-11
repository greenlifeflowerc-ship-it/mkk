// Dev-only entry point: boots straight into an arcade fight on the
// cemetery stage, skipping the menus. Used for quick visual verification:
//   flutter run -d windows -t lib/dev_fight_main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/ai/cpu_brain.dart';
import 'game/match/match_config.dart';
import 'ui/screens/fight_screen.dart';
import 'ui/theme/ui_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: UiTheme.materialTheme(),
      home: const FightScreen(
        config: MatchConfig(
          mode: GameMode.arcade,
          p1FighterId: 'night_blade',
          p2FighterId: 'grave_warden',
          stageId: 'haunted_cemetery',
          difficulty: CpuDifficulty.normal,
        ),
      ),
    ),
  );
}
