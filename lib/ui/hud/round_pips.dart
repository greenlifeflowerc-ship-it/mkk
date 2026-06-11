import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../theme/ui_theme.dart';

/// Round-win indicators under each health bar: one angular ember-lit shard
/// per round needed (original design, no franchise iconography).
class RoundPips extends StatelessWidget {
  const RoundPips({super.key, required this.wins, required this.mirrored});

  final int wins;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final pips = [
      for (var i = 0; i < GameConstants.roundsToWin; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: CustomPaint(
            size: const Size(22, 22),
            painter: _PipPainter(filled: i < wins),
          ),
        ),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: mirrored ? pips.reversed.toList() : pips,
    );
  }
}

class _PipPainter extends CustomPainter {
  _PipPainter({required this.filled});

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Angular shard: a diamond with a notched crown.
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.85, h * 0.3)
      ..lineTo(w * 0.7, h * 0.45)
      ..lineTo(w, h * 0.55)
      ..lineTo(w / 2, h)
      ..lineTo(0, h * 0.55)
      ..lineTo(w * 0.3, h * 0.45)
      ..lineTo(w * 0.15, h * 0.3)
      ..close();
    if (filled) {
      canvas.drawPath(path, Paint()..color = UiTheme.bloodRed);
      canvas.drawPath(
        path,
        Paint()
          ..color = UiTheme.emberOrange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = UiTheme.metalGrey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_PipPainter old) => old.filled != filled;
}
