import 'package:flame/camera.dart';
import 'package:flame/extensions.dart';

import '../../core/constants/game_constants.dart';

/// Dual-target fight camera (§3.6): smoothed midpoint follow, distance
/// zoom (close-up 1.15x, fit-both when far, clamped 0.85-1.15), slight rise
/// on jumps, stage-bound clamping and deterministic tick-based screen shake.
class FightCamera {
  FightCamera(this.camera);

  final CameraComponent camera;

  static const double followLerp = 0.08;
  static const double zoomLerp = 0.06;
  static const double minZoom = 0.85;
  static const double maxZoom = 1.15;

  /// Margin kept beside each fighter when fitting both on screen, plus an
  /// allowance for body width (the fit formula hits exactly 0.85 at 1500 px
  /// distance and 1.15 at <= 600 px).
  static const double fitMarginPerSide = 180;
  static const double fighterAllowance = 400;

  static const double maxJumpRise = 120;

  double _zoom = 1.0;
  double _smoothX = 0;
  double _smoothY = GameConstants.logicalHeight / 2;

  int _shakeTicksRemaining = 0;
  int _shakeDuration = 0;
  double _shakeAmplitude = 0;
  int _shakePhase = 0;

  void snapTo(double x) {
    _smoothX = _clampX(x, _zoom);
    _smoothY = GameConstants.logicalHeight / 2;
    _apply();
  }

  /// Begins a screen shake; amplitude in logical px, scaled by hit weight.
  void shake({required int ticks, required double amplitude}) {
    _shakeTicksRemaining = ticks;
    _shakeDuration = ticks;
    _shakeAmplitude = amplitude;
  }

  /// Called once per logic tick with both fighters' feet positions and the
  /// highest (smallest y) of the two — drives rise during jumps.
  void followTick({
    required double x1,
    required double x2,
    required double highestY,
  }) {
    final distance = (x1 - x2).abs();
    final targetZoom = (GameConstants.logicalWidth /
            (distance + 2 * fitMarginPerSide + fighterAllowance))
        .clamp(minZoom, maxZoom);
    _zoom += (targetZoom - _zoom) * zoomLerp;

    final targetX = _clampX((x1 + x2) / 2, _zoom);
    _smoothX += (targetX - _smoothX) * followLerp;

    final rise = ((GameConstants.floorY - highestY) * 0.3)
        .clamp(0.0, maxJumpRise);
    final targetY = GameConstants.logicalHeight / 2 - rise;
    _smoothY += (targetY - _smoothY) * followLerp;

    _apply();
  }

  void _apply() {
    var shakeOffset = 0.0;
    if (_shakeTicksRemaining > 0) {
      final decay = _shakeTicksRemaining / _shakeDuration;
      shakeOffset =
          _shakeAmplitude * decay * (_shakePhase.isEven ? 1 : -1);
      _shakePhase++;
      _shakeTicksRemaining--;
    }
    camera.viewfinder.zoom = _zoom;
    // Viewfinder.position returns a copy; always assign via the setter.
    camera.viewfinder.position =
        Vector2(_smoothX, _smoothY + shakeOffset);
  }

  double _clampX(double x, double zoom) {
    final halfView = GameConstants.logicalWidth / zoom / 2;
    final min = GameConstants.stageLeftBound + halfView;
    final max = GameConstants.stageRightBound - halfView;
    if (max <= min) return (min + max) / 2;
    return x.clamp(min, max);
  }

  double get x => _smoothX;
}
