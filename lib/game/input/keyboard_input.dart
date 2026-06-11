import 'package:flutter/services.dart';

import 'input_controller.dart';
import 'input_snapshot.dart';

/// Key bindings for one keyboard-controlled player. Rebinding UI lands in
/// Phase 8; these are the documented defaults.
class KeyboardBindings {
  const KeyboardBindings({
    required this.left,
    required this.right,
    required this.up,
    required this.down,
    required this.lightAttack,
    required this.heavyAttack,
    required this.special,
    required this.block,
  });

  final LogicalKeyboardKey left;
  final LogicalKeyboardKey right;
  final LogicalKeyboardKey up;
  final LogicalKeyboardKey down;
  final LogicalKeyboardKey lightAttack;
  final LogicalKeyboardKey heavyAttack;
  final LogicalKeyboardKey special;
  final LogicalKeyboardKey block;

  static const KeyboardBindings player1 = KeyboardBindings(
    left: LogicalKeyboardKey.keyA,
    right: LogicalKeyboardKey.keyD,
    up: LogicalKeyboardKey.keyW,
    down: LogicalKeyboardKey.keyS,
    lightAttack: LogicalKeyboardKey.keyJ,
    heavyAttack: LogicalKeyboardKey.keyK,
    special: LogicalKeyboardKey.keyL,
    block: LogicalKeyboardKey.semicolon,
  );

  static const KeyboardBindings player2 = KeyboardBindings(
    left: LogicalKeyboardKey.arrowLeft,
    right: LogicalKeyboardKey.arrowRight,
    up: LogicalKeyboardKey.arrowUp,
    down: LogicalKeyboardKey.arrowDown,
    lightAttack: LogicalKeyboardKey.numpad1,
    heavyAttack: LogicalKeyboardKey.numpad2,
    special: LogicalKeyboardKey.numpad3,
    block: LogicalKeyboardKey.numpad0,
  );
}

/// Samples a shared pressed-key set (fed by the game's keyboard events)
/// against one player's bindings.
class KeyboardInput implements InputController {
  KeyboardInput(this.bindings, this.pressedKeys);

  final KeyboardBindings bindings;

  /// Live set owned by the game; updated on every key event.
  final Set<LogicalKeyboardKey> pressedKeys;

  InputSnapshot _previous = InputSnapshot.empty;

  @override
  InputSnapshot sample() {
    final snapshot = InputSnapshot.withEdges(
      left: pressedKeys.contains(bindings.left),
      right: pressedKeys.contains(bindings.right),
      up: pressedKeys.contains(bindings.up),
      down: pressedKeys.contains(bindings.down),
      lightAttack: pressedKeys.contains(bindings.lightAttack),
      heavyAttack: pressedKeys.contains(bindings.heavyAttack),
      special: pressedKeys.contains(bindings.special),
      block: pressedKeys.contains(bindings.block),
      previous: _previous,
    );
    _previous = snapshot;
    return snapshot;
  }
}
