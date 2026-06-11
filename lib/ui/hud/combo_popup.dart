import 'package:flutter/material.dart';

import '../theme/ui_theme.dart';

/// "N HITS" callout that rises near the comboed side and fades shortly
/// after the combo drops.
class ComboPopup extends StatelessWidget {
  const ComboPopup({
    super.key,
    required this.hits,
    required this.ticksSinceChange,
  });

  final int hits;

  /// Logic ticks since the last hit of the combo; drives the fade.
  final int ticksSinceChange;

  static const int _visibleTicks = 70;

  @override
  Widget build(BuildContext context) {
    if (hits < 2 || ticksSinceChange > _visibleTicks) {
      return const SizedBox.shrink();
    }
    final fade =
        (1 - (ticksSinceChange - 40) / 30).clamp(0.0, 1.0).toDouble();
    return Opacity(
      opacity: fade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$hits',
            style: const TextStyle(
              color: UiTheme.emberOrange,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Color(0xCC000000), blurRadius: 8)],
            ),
          ),
          const Text(
            'HITS',
            style: TextStyle(
              color: UiTheme.boneWhite,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 5,
              shadows: [Shadow(color: Color(0xCC000000), blurRadius: 6)],
            ),
          ),
        ],
      ),
    );
  }
}
