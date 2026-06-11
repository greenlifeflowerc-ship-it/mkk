import '../input/input_controller.dart';
import '../input/input_snapshot.dart';

/// CPU difficulty: how fast it reacts to threats and how often it fumbles.
enum CpuDifficulty {
  easy(reactionTicks: 24, mistakePercent: 45),
  normal(reactionTicks: 14, mistakePercent: 25),
  hard(reactionTicks: 7, mistakePercent: 10);

  const CpuDifficulty({
    required this.reactionTicks,
    required this.mistakePercent,
  });

  final int reactionTicks;
  final int mistakePercent;
}

enum _Intent {
  idle,
  walkForward,
  walkBackward,
  jumpForward,
  attackLight,
  attackHeavy,
  attackSpecial,
  block,
  blockLow,
}

/// Reactive tick-based opponent. Deterministic: decisions come from a
/// seeded LCG, never wall-clock randomness. Reads the match through
/// injected callbacks wired by the game once both fighters exist.
class CpuBrain implements InputController {
  CpuBrain({this.difficulty = CpuDifficulty.normal});

  CpuDifficulty difficulty;

  /// Horizontal distance to the opponent, logical px.
  double Function()? distance;

  /// Sign of the direction towards the opponent (+1 = right).
  double Function()? directionSign;

  /// True while the opponent is in attack startup or active frames.
  bool Function()? opponentThreatening;

  bool Function()? opponentAirborne;

  int _seed = 0x51F1;
  int _threatTicks = 0;
  int _holdTicks = 0;
  _Intent _intent = _Intent.idle;
  InputSnapshot _previous = InputSnapshot.empty;

  int _rand(int n) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % n;
  }

  @override
  InputSnapshot sample() {
    _trackThreat();
    if (_holdTicks > 0) {
      _holdTicks--;
    } else {
      _decide();
    }
    return _emit();
  }

  void _trackThreat() {
    if (opponentThreatening?.call() ?? false) {
      _threatTicks++;
      if (_threatTicks == difficulty.reactionTicks &&
          _rand(100) >= difficulty.mistakePercent) {
        _intent = _rand(3) == 0 ? _Intent.blockLow : _Intent.block;
        _holdTicks = 26;
      }
    } else {
      _threatTicks = 0;
    }
  }

  void _decide() {
    final d = distance?.call() ?? 9999;
    final airborne = opponentAirborne?.call() ?? false;

    if (airborne && d < 620) {
      _set(_Intent.attackHeavy, 1); // Anti-air.
      return;
    }
    if (d > 700) {
      if (_rand(10) == 0) {
        _set(_Intent.jumpForward, 8);
      } else if (_rand(12) == 0) {
        _set(_Intent.attackSpecial, 1); // Fireball from range.
      } else {
        _set(_Intent.walkForward, 10 + _rand(14));
      }
      return;
    }
    if (d > 420) {
      switch (_rand(10)) {
        case 0 || 1 || 2 || 3 || 4:
          _set(_Intent.walkForward, 8 + _rand(8));
        case 5 || 6:
          _set(_Intent.attackHeavy, 1);
        case 7:
          _set(_Intent.attackSpecial, 1);
        case 8:
          _set(_Intent.walkBackward, 8 + _rand(6));
        default:
          _set(_Intent.idle, 4 + _rand(6));
      }
      return;
    }
    // Point-blank.
    switch (_rand(10)) {
      case 0 || 1 || 2 || 3:
        _set(_Intent.attackLight, 1);
      case 4 || 5:
        _set(_Intent.attackHeavy, 1);
      case 6:
        _set(_Intent.attackSpecial, 1);
      case 7:
        _set(_Intent.block, 14 + _rand(10));
      case 8:
        _set(_Intent.walkBackward, 8 + _rand(8));
      default:
        _set(_Intent.idle, 3 + _rand(5));
    }
  }

  void _set(_Intent intent, int holdTicks) {
    _intent = intent;
    _holdTicks = holdTicks;
  }

  InputSnapshot _emit() {
    final towards = directionSign?.call() ?? 1;
    final forwardRight = towards > 0;
    var left = false, right = false, up = false, down = false;
    var light = false, heavy = false, special = false, block = false;
    switch (_intent) {
      case _Intent.idle:
        break;
      case _Intent.walkForward:
        right = forwardRight;
        left = !forwardRight;
      case _Intent.walkBackward:
        left = forwardRight;
        right = !forwardRight;
      case _Intent.jumpForward:
        up = true;
        right = forwardRight;
        left = !forwardRight;
      case _Intent.attackLight:
        light = true;
        _intent = _Intent.idle;
      case _Intent.attackHeavy:
        heavy = true;
        _intent = _Intent.idle;
      case _Intent.attackSpecial:
        special = true;
        _intent = _Intent.idle;
      case _Intent.block:
        block = true;
      case _Intent.blockLow:
        block = true;
        down = true;
    }
    final snapshot = InputSnapshot.withEdges(
      left: left,
      right: right,
      up: up,
      down: down,
      lightAttack: light,
      heavyAttack: heavy,
      special: special,
      block: block,
      previous: _previous,
    );
    _previous = snapshot;
    return snapshot;
  }
}
