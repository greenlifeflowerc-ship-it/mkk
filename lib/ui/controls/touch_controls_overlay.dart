import 'package:flutter/material.dart';

import '../../game/input/touch_input.dart';
import '../theme/ui_theme.dart';
import 'action_buttons.dart';
import 'virtual_dpad.dart';

/// Full-screen touch control layer: d-pad bottom-left, action buttons
/// bottom-right. Sits above the GameWidget in a Stack, inside SafeArea so
/// notches and punch-holes are respected.
class TouchControlsOverlay extends StatelessWidget {
  const TouchControlsOverlay({super.key, required this.state});

  final TouchInputState state;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Opacity(
        opacity: UiTheme.touchControlOpacity,
        child: Stack(
          children: [
            Positioned(
              left: 28,
              bottom: 24,
              child: VirtualDpad(state: state),
            ),
            Positioned(
              right: 20,
              bottom: 16,
              child: ActionButtons(state: state),
            ),
          ],
        ),
      ),
    );
  }
}
