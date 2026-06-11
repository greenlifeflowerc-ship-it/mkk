import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/ui_theme.dart';

/// Instant pause overlay: darkens and blurs the frozen game underneath.
/// OPTIONS arrives with the Phase 8 menu pass.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onQuitMatch,
  });

  final VoidCallback onResume;
  final VoidCallback onQuitMatch;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: ColoredBox(
        color: const Color(0xB30A0A0C),
        child: Center(
          child: MetalPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PAUSED',
                  style: TextStyle(
                    color: UiTheme.boneWhite,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                  ),
                ),
                const SizedBox(height: 36),
                MenuActionButton(label: 'RESUME', onPressed: onResume),
                const SizedBox(height: 16),
                MenuActionButton(label: 'QUIT MATCH', onPressed: onQuitMatch),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared chunky menu button: riveted dark-steel 9-slice plate (generated
/// by tool/import_effects.dart) with an ember glow while pressed.
class MenuActionButton extends StatefulWidget {
  const MenuActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<MenuActionButton> createState() => _MenuActionButtonState();
}

class _MenuActionButtonState extends State<MenuActionButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 50),
        child: Container(
          width: 280,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/images/ui/button.png'),
              centerSlice: Rect.fromLTWH(16, 16, 16, 16),
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
            boxShadow: [
              if (_down)
                BoxShadow(
                  color: UiTheme.emberOrange.withValues(alpha: 0.55),
                  blurRadius: 16,
                ),
            ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _down ? UiTheme.emberOrange : UiTheme.boneWhite,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}

/// Riveted dark-steel 9-slice panel for menu/dialog content.
class MetalPanel extends StatelessWidget {
  const MetalPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(36),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/ui/panel.png'),
          centerSlice: Rect.fromLTWH(16, 16, 16, 16),
          fit: BoxFit.fill,
          filterQuality: FilterQuality.none,
        ),
      ),
      child: child,
    );
  }
}
