import 'package:flutter/material.dart';

import '../../game/input/touch_input.dart';
import '../theme/ui_theme.dart';

/// Floating 8-way d-pad in the arcade-metal style: a ringed base with
/// direction notches that light up, and a thumb puck that follows the drag.
/// Dead zone: 12% of the pad radius.
class VirtualDpad extends StatefulWidget {
  const VirtualDpad({super.key, required this.state, this.diameter = 230});

  final TouchInputState state;
  final double diameter;

  @override
  State<VirtualDpad> createState() => _VirtualDpadState();
}

class _VirtualDpadState extends State<VirtualDpad> {
  static const double _deadZoneFraction = 0.12;

  Offset _thumb = Offset.zero;

  void _updateFrom(Offset localPosition) {
    final radius = widget.diameter / 2;
    final center = Offset(radius, radius);
    var delta = localPosition - center;
    if (delta.distance > radius) {
      delta = delta / delta.distance * radius;
    }
    setState(() => _thumb = delta);

    final state = widget.state;
    if (delta.distance < radius * _deadZoneFraction) {
      state.releaseDirections();
      return;
    }
    final dx = delta.dx / radius;
    final dy = delta.dy / radius;
    state.left = dx < -0.35;
    state.right = dx > 0.35;
    state.up = dy < -0.35;
    state.down = dy > 0.35;
  }

  void _release() {
    setState(() => _thumb = Offset.zero);
    widget.state.releaseDirections();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.diameter / 2;
    final s = widget.state;
    return GestureDetector(
      onPanDown: (d) => _updateFrom(d.localPosition),
      onPanUpdate: (d) => _updateFrom(d.localPosition),
      onPanEnd: (_) => _release(),
      onPanCancel: _release,
      child: SizedBox(
        width: widget.diameter,
        height: widget.diameter,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.diameter,
              height: widget.diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [UiTheme.metalDark, Color(0xFF101014)],
                ),
                border: Border.all(color: UiTheme.metalGrey, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            _notch(Alignment.topCenter, Icons.keyboard_arrow_up, s.up),
            _notch(Alignment.bottomCenter, Icons.keyboard_arrow_down, s.down),
            _notch(Alignment.centerLeft, Icons.keyboard_arrow_left, s.left),
            _notch(Alignment.centerRight, Icons.keyboard_arrow_right, s.right),
            Transform.translate(
              offset: _thumb * 0.55,
              child: Container(
                width: radius * 0.85,
                height: radius * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF55555E), UiTheme.metalDark],
                  ),
                  border: Border.all(color: UiTheme.metalGrey, width: 3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notch(Alignment alignment, IconData icon, bool active) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 30,
          color: active ? UiTheme.emberOrange : UiTheme.metalGrey,
        ),
      ),
    );
  }
}
