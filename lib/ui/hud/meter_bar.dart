import 'package:flutter/material.dart';

import '../../game/match/meter_system.dart';
import '../theme/ui_theme.dart';

/// Three-segment super meter, bottom corners, ember glow as it fills and a
/// pulse on every banked bar.
class MeterBar extends StatelessWidget {
  const MeterBar({
    super.key,
    required this.meter,
    required this.mirrored,
    required this.pulsePhase,
  });

  final MeterSystem meter;
  final bool mirrored;
  final double pulsePhase;

  @override
  Widget build(BuildContext context) {
    final segments = [
      for (var i = 0; i < MeterSystem.maxBars; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _MeterSegment(
            fill: meter.segmentFraction(i),
            charged: meter.bars > i,
            pulsePhase: pulsePhase,
          ),
        ),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: mirrored ? segments.reversed.toList() : segments,
    );
  }
}

class _MeterSegment extends StatelessWidget {
  const _MeterSegment({
    required this.fill,
    required this.charged,
    required this.pulsePhase,
  });

  final double fill;
  final bool charged;
  final double pulsePhase;

  @override
  Widget build(BuildContext context) {
    final glow = charged ? 0.55 + 0.45 * (1 - pulsePhase) : 0.0;
    return Container(
      width: 64,
      height: 12,
      decoration: BoxDecoration(
        color: UiTheme.metalDark,
        border: Border.all(color: UiTheme.metalGrey, width: 2),
        boxShadow: [
          if (charged)
            BoxShadow(
              color: UiTheme.emberOrange.withValues(alpha: glow * 0.7),
              blurRadius: 10,
            ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fill,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  UiTheme.emberOrange,
                  charged ? UiTheme.boneWhite : UiTheme.bloodRed,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
