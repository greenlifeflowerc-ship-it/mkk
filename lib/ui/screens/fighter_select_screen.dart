import 'package:flutter/material.dart';

import '../../data/fighters/roster.dart';
import '../../game/ai/cpu_brain.dart';
import '../../game/match/match_config.dart';
import '../theme/ui_theme.dart';
import 'stage_select_screen.dart';

/// Fighter selection grid built for N fighters. P1 picks first, then P2
/// (human in versus/training, CPU difficulty chips in arcade where the
/// opponent is also chosen by P1).
class FighterSelectScreen extends StatefulWidget {
  const FighterSelectScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  State<FighterSelectScreen> createState() => _FighterSelectScreenState();
}

class _FighterSelectScreenState extends State<FighterSelectScreen> {
  String? _p1Pick;
  CpuDifficulty _difficulty = CpuDifficulty.normal;

  bool get _pickingP1 => _p1Pick == null;

  void _onPick(String fighterId) {
    if (_pickingP1) {
      setState(() => _p1Pick = fighterId);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StageSelectScreen(
          mode: widget.mode,
          p1FighterId: _p1Pick!,
          p2FighterId: fighterId,
          difficulty: _difficulty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _pickingP1
        ? 'P1 — CHOOSE YOUR FIGHTER'
        : switch (widget.mode) {
            GameMode.arcade => 'CHOOSE YOUR OPPONENT',
            GameMode.versus => 'P2 — CHOOSE YOUR FIGHTER',
            GameMode.training => 'CHOOSE THE DUMMY',
          };
    return Scaffold(
      backgroundColor: UiTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            Text(
              prompt,
              style: TextStyle(
                color: _pickingP1 ? UiTheme.boneWhite : UiTheme.emberOrange,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    for (final id in rosterIds)
                      _FighterTile(
                        fighterId: id,
                        selected: _p1Pick == id,
                        onTap: () => _onPick(id),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.mode == GameMode.arcade) _difficultyPicker(),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _difficultyPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final d in CpuDifficulty.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(
                d.name.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              selected: _difficulty == d,
              selectedColor: UiTheme.bloodRed,
              backgroundColor: UiTheme.metalDark,
              labelStyle: const TextStyle(color: UiTheme.boneWhite),
              onSelected: (_) => setState(() => _difficulty = d),
            ),
          ),
      ],
    );
  }
}

class _FighterTile extends StatelessWidget {
  const _FighterTile({
    required this.fighterId,
    required this.selected,
    required this.onTap,
  });

  final String fighterId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = fighterDataById(fighterId);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: UiTheme.metalDark,
          border: Border.all(
            color: selected ? UiTheme.emberOrange : UiTheme.metalGrey,
            width: 3,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: UiTheme.emberOrange.withValues(alpha: 0.5),
                blurRadius: 16,
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/images/fighters/$fighterId/portrait.png',
                width: 132,
                height: 132,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
              ),
            ),
            Container(
              width: double.infinity,
              color: selected ? UiTheme.bloodRed : UiTheme.metalGrey,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                data.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: UiTheme.boneWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
