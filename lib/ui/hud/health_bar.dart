import 'package:flutter/material.dart';

import '../theme/ui_theme.dart';

/// Skewed-parallelogram health bar with a metal frame. Red bar drains
/// instantly; a yellow "ghost" trail (driven by the match manager) follows
/// over ~30 ticks. Flashes white on hit, pulses when below 20%.
class HealthBar extends StatelessWidget {
  const HealthBar({
    super.key,
    required this.fraction,
    required this.ghost,
    required this.mirrored,
    required this.flash,
    required this.pulsePhase,
    required this.name,
  });

  /// Current health [0, 1] and the delayed ghost value behind it.
  final double fraction;
  final double ghost;

  /// True for the right-hand (P2) bar: drains towards screen center.
  final bool mirrored;

  /// White flash, set for a few ticks after taking a hit.
  final bool flash;

  /// 0..1 sawtooth from the logic tick; drives the low-health pulse.
  final double pulsePhase;

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          mirrored ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: CustomPaint(
            size: Size.infinite,
            painter: _HealthBarPainter(
              fraction: fraction,
              ghost: ghost,
              mirrored: mirrored,
              flash: flash,
              pulsePhase: pulsePhase,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3, left: 14, right: 14),
          child: Text(
            name,
            style: const TextStyle(
              color: UiTheme.boneWhite,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _HealthBarPainter extends CustomPainter {
  _HealthBarPainter({
    required this.fraction,
    required this.ghost,
    required this.mirrored,
    required this.flash,
    required this.pulsePhase,
  });

  final double fraction;
  final double ghost;
  final bool mirrored;
  final bool flash;
  final double pulsePhase;

  static const double _skew = 14;

  Path _barPath(Size size, double f) {
    // Parallelogram leaning right, anchored at the outer (left) edge;
    // the canvas is mirrored for the P2 side.
    final w = (size.width - _skew) * f;
    return Path()
      ..moveTo(_skew, 0)
      ..lineTo(_skew + w, 0)
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (mirrored) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    canvas.drawPath(_barPath(size, 1), Paint()..color = UiTheme.metalDark);
    canvas.drawPath(
      _barPath(size, ghost.clamp(0, 1)),
      Paint()..color = const Color(0xFFC9A227),
    );

    final lowHealth = fraction <= 0.2 && fraction > 0;
    final pulse = lowHealth ? 0.75 + 0.25 * (1 - pulsePhase) : 1.0;
    final healthRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawPath(
      _barPath(size, fraction.clamp(0, 1)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            UiTheme.bloodRed.withValues(alpha: pulse),
            UiTheme.emberOrange.withValues(alpha: pulse),
          ],
        ).createShader(healthRect),
    );

    if (flash) {
      canvas.drawPath(
        _barPath(size, fraction.clamp(0, 1)),
        Paint()..color = const Color(0xCCFFFFFF),
      );
    }

    canvas.drawPath(
      _barPath(size, 1),
      Paint()
        ..color = UiTheme.metalGrey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HealthBarPainter old) =>
      old.fraction != fraction ||
      old.ghost != ghost ||
      old.flash != flash ||
      old.pulsePhase != pulsePhase;
}
