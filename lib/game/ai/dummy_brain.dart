import '../input/input_controller.dart';
import '../input/input_snapshot.dart';

/// Training-dummy behaviours for Milestone 1. The reactive CPU opponent
/// (Phase 5) lives in cpu_brain.dart.
enum DummyMode { idle, blockAll, blockLow, walkAtPlayer, blockRandom }

/// An [InputController] that produces scripted dummy behaviour instead of
/// reading hardware. Deterministic: "random" blocking is tick-pattern based.
class DummyBrain implements InputController {
  DummyBrain({this.mode = DummyMode.idle});

  DummyMode mode;

  /// Sign of the direction towards the opponent (+1 right, -1 left); wired
  /// by the game once both fighters exist.
  double Function()? opponentDirection;

  int _tick = 0;

  @override
  InputSnapshot sample() {
    _tick++;
    switch (mode) {
      case DummyMode.idle:
        return InputSnapshot.empty;
      case DummyMode.blockAll:
        return const InputSnapshot(block: true);
      case DummyMode.blockLow:
        return const InputSnapshot(block: true, down: true);
      case DummyMode.walkAtPlayer:
        final direction = opponentDirection?.call() ?? 0;
        return InputSnapshot(left: direction < 0, right: direction > 0);
      case DummyMode.blockRandom:
        // Blocks in alternating ~0.75 s bursts.
        final blocking = (_tick ~/ 45).isEven;
        return InputSnapshot(block: blocking);
    }
  }
}
