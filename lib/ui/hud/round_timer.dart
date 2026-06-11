import 'package:flutter/material.dart';

import '../theme/ui_theme.dart';

/// Center-top round timer. Flips to red and pulses under 10 seconds.
class RoundTimer extends StatelessWidget {
  const RoundTimer({
    super.key,
    required this.seconds,
    required this.pulsePhase,
  });

  final int seconds;

  /// 0..1 sawtooth from the logic tick; drives the low-time pulse.
  final double pulsePhase;

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= 10;
    final scale = urgent ? 1.0 + 0.12 * (1 - pulsePhase) : 1.0;
    return Transform.scale(
      scale: scale,
      child: Text(
        seconds.toString().padLeft(2, '0'),
        style: TextStyle(
          color: urgent ? UiTheme.bloodRed : UiTheme.boneWhite,
          fontSize: 44,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          shadows: const [
            Shadow(color: Color(0xCC000000), offset: Offset(0, 3), blurRadius: 6),
          ],
        ),
      ),
    );
  }
}
