import 'input_snapshot.dart';

/// Source of per-tick input for one fighter. Implementations: keyboard,
/// touch overlay, dummy/CPU brains.
abstract class InputController {
  /// Called exactly once per logic tick; must derive press edges internally.
  InputSnapshot sample();
}
