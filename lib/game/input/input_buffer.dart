import '../../core/constants/game_constants.dart';
import 'input_snapshot.dart';

/// Buttons that can be buffered for delayed execution.
enum BufferedButton { light, heavy, special }

class _PressEvent {
  _PressEvent(this.button, this.tick);

  final BufferedButton button;
  final int tick;
  bool consumed = false;
}

/// Remembers recent button presses so an attack input during recovery
/// executes on the first legal tick. Each press triggers at most one action.
class InputBuffer {
  final List<_PressEvent> _presses = [];
  final List<InputSnapshot> _history = [];
  int _currentTick = 0;

  /// Snapshot history (most recent last) covering the motion-command
  /// window; consumed by the motion parser.
  List<InputSnapshot> get history => List.unmodifiable(_history);

  void push(InputSnapshot snapshot, int tick) {
    _currentTick = tick;
    _history.add(snapshot);
    if (_history.length > GameConstants.motionWindowTicks) {
      _history.removeAt(0);
    }
    if (snapshot.lightPressed) {
      _presses.add(_PressEvent(BufferedButton.light, tick));
    }
    if (snapshot.heavyPressed) {
      _presses.add(_PressEvent(BufferedButton.heavy, tick));
    }
    if (snapshot.specialPressed) {
      _presses.add(_PressEvent(BufferedButton.special, tick));
    }
    _presses.removeWhere(
      (p) => p.consumed || _currentTick - p.tick > GameConstants.inputBufferTicks,
    );
  }

  /// Consumes the most recent unconsumed press of [button] that happened
  /// within the last [leniencyTicks] ticks. Returns true when one existed.
  bool consumePress(BufferedButton button,
      {int leniencyTicks = GameConstants.defaultInputLeniencyTicks}) {
    for (var i = _presses.length - 1; i >= 0; i--) {
      final press = _presses[i];
      if (press.consumed || press.button != button) continue;
      if (_currentTick - press.tick > leniencyTicks) continue;
      press.consumed = true;
      return true;
    }
    return false;
  }

  void clear() {
    _presses.clear();
    _history.clear();
  }
}
