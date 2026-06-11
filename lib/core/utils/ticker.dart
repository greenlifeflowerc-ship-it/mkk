import '../constants/game_constants.dart';

/// Fixed 60 Hz logic step accumulator. Rendering runs at display rate; logic
/// advances in exact [GameConstants.tickSeconds] steps so all frame data is
/// deterministic.
class GameTicker {
  GameTicker(this.onTick);

  final void Function() onTick;

  /// Multiplier on accumulated time. 1.0 normally, 0.4 during KO slow-mo,
  /// 0.0 while paused.
  double timeScale = 1.0;

  int tickCount = 0;
  double _accumulator = 0;

  /// Clamp to avoid a spiral of death after a long frame hitch.
  static const double _maxAccumulated = 0.25;

  void advance(double dt) {
    _accumulator += dt * timeScale;
    if (_accumulator > _maxAccumulated) {
      _accumulator = _maxAccumulated;
    }
    while (_accumulator >= GameConstants.tickSeconds) {
      _accumulator -= GameConstants.tickSeconds;
      tickCount++;
      onTick();
    }
  }

  /// Fraction [0, 1) of the way from the last logic state to the next one;
  /// used to interpolate rendered positions.
  double get interpolation =>
      (_accumulator / GameConstants.tickSeconds).clamp(0.0, 1.0);
}
