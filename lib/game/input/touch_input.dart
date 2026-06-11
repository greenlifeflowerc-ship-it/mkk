import 'input_controller.dart';
import 'input_snapshot.dart';

/// Mutable state written by the Flutter touch overlay (d-pad + buttons) and
/// read once per logic tick by [TouchInput]. Plain fields: the overlay
/// writes on pointer events, the game samples at 60 Hz.
class TouchInputState {
  bool left = false;
  bool right = false;
  bool up = false;
  bool down = false;
  bool lightAttack = false;
  bool heavyAttack = false;
  bool special = false;
  bool block = false;

  void releaseDirections() {
    left = false;
    right = false;
    up = false;
    down = false;
  }
}

/// Adapts the on-screen controls to the per-tick [InputController] contract.
class TouchInput implements InputController {
  TouchInput(this.state);

  final TouchInputState state;

  InputSnapshot _previous = InputSnapshot.empty;

  @override
  InputSnapshot sample() {
    final snapshot = InputSnapshot.withEdges(
      left: state.left,
      right: state.right,
      up: state.up,
      down: state.down,
      lightAttack: state.lightAttack,
      heavyAttack: state.heavyAttack,
      special: state.special,
      block: state.block,
      previous: _previous,
    );
    _previous = snapshot;
    return snapshot;
  }
}

/// Merges two controllers (e.g. keyboard and touch) so either can drive the
/// same fighter; useful on desktops with touch screens.
class MergedInput implements InputController {
  MergedInput(this.a, this.b);

  final InputController a;
  final InputController b;

  @override
  InputSnapshot sample() {
    final sa = a.sample();
    final sb = b.sample();
    return InputSnapshot(
      left: sa.left || sb.left,
      right: sa.right || sb.right,
      up: sa.up || sb.up,
      down: sa.down || sb.down,
      lightAttack: sa.lightAttack || sb.lightAttack,
      heavyAttack: sa.heavyAttack || sb.heavyAttack,
      special: sa.special || sb.special,
      block: sa.block || sb.block,
      lightPressed: sa.lightPressed || sb.lightPressed,
      heavyPressed: sa.heavyPressed || sb.heavyPressed,
      specialPressed: sa.specialPressed || sb.specialPressed,
      upPressed: sa.upPressed || sb.upPressed,
    );
  }
}
