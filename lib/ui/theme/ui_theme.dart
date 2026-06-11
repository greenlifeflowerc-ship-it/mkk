import 'package:flutter/material.dart';

/// Dark-arcade visual language shared by every screen and overlay.
class UiTheme {
  UiTheme._();

  static const Color background = Color(0xFF0A0A0C);
  static const Color bloodRed = Color(0xFFB3001B);
  static const Color emberOrange = Color(0xFFFF6A00);
  static const Color boneWhite = Color(0xFFE8E4D8);
  static const Color metalGrey = Color(0xFF3A3A40);
  static const Color metalDark = Color(0xFF1A1A1E);

  /// Default opacity for the touch control overlay (user adjustable in
  /// Options, Phase 8).
  static const double touchControlOpacity = 0.45;

  static ThemeData materialTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: bloodRed,
        secondary: emberOrange,
        surface: metalDark,
      ),
    );
  }
}
