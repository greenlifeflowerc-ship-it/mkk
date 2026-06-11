import 'package:flutter/material.dart';

import '../../game/input/touch_input.dart';
import '../theme/ui_theme.dart';

/// The four attack/defense buttons arranged in an arc: PUNCH, KICK,
/// SPECIAL, BLOCK — beveled arcade-metal buttons that glow while held.
class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key, required this.state});

  final TouchInputState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 330,
      height: 310,
      child: Stack(
        children: [
          _place(left: 6, top: 134, label: 'P', sub: 'PUNCH',
              color: UiTheme.bloodRed, onChanged: (v) => state.lightAttack = v),
          _place(left: 112, top: 34, label: 'K', sub: 'KICK',
              color: UiTheme.bloodRed, onChanged: (v) => state.heavyAttack = v),
          _place(left: 218, top: 10, label: 'S', sub: 'SPECIAL',
              color: UiTheme.emberOrange, onChanged: (v) => state.special = v),
          _place(left: 200, top: 154, label: 'B', sub: 'BLOCK',
              color: const Color(0xFF6FA8DC), onChanged: (v) => state.block = v),
        ],
      ),
    );
  }

  Widget _place({
    required double left,
    required double top,
    required String label,
    required String sub,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: _ArcadeButton(
          label: label, sub: sub, color: color, onChanged: onChanged),
    );
  }
}

class _ArcadeButton extends StatefulWidget {
  const _ArcadeButton({
    required this.label,
    required this.sub,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final String sub;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  State<_ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<_ArcadeButton> {
  bool _down = false;

  void _set(bool value) {
    setState(() => _down = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    // 100 dp comfortably exceeds the 64 dp minimum touch target.
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 40),
        child: Container(
          width: 100,
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _down
                  ? [widget.color, Color.lerp(widget.color, Colors.black, 0.5)!]
                  : [UiTheme.metalGrey, UiTheme.metalDark],
            ),
            border: Border.all(
              color: _down ? UiTheme.boneWhite : widget.color,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _down
                    ? widget.color.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.6),
                blurRadius: _down ? 18 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: _down ? UiTheme.boneWhite : widget.color,
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                widget.sub,
                style: const TextStyle(
                  color: UiTheme.boneWhite,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
