import '../combat/hit_event.dart';
import '../combat/move_data.dart';
import '../input/input_buffer.dart';
import '../input/input_snapshot.dart';
import '../input/motion_parser.dart';
import 'facing.dart';
import 'fighter_data.dart';
import 'fighter_state.dart';

/// Physical intents produced by the state machine each tick; the owning
/// component integrates them into velocity/position.
class MotionIntent {
  double velocityX = 0;
  bool startJump = false;
  double jumpVelocityX = 0;

  void reset() {
    velocityX = 0;
    startJump = false;
    jumpVelocityX = 0;
  }
}

/// Deterministic fighter state machine. Single source of truth for
/// [state] and [stateTick]; transitions are validated against a data table,
/// cancels against the current move's [CancelRule]s.
class CombatStateMachine {
  CombatStateMachine(this.data, {this.facing = Facing.right});

  final FighterData data;
  Facing facing;

  FighterState state = FighterState.idle;

  /// Ticks since entering [state]; 0 on the entry tick.
  int stateTick = 0;

  MoveData? currentMove;

  /// True once the current move has touched the opponent (hit or block);
  /// gates contact-only cancels and one-hit-per-activation.
  bool moveHasConnected = false;

  /// Remaining hitstun or blockstun ticks.
  int stunTicksRemaining = 0;

  /// Set by the match layer when this fighter's health reaches zero; a
  /// completed knockdown then ends in defeat instead of get-up.
  bool koFlag = false;

  /// Mirrored from the fighter's meter each tick; selects the EX special.
  int meterBars = 0;

  /// Set when an EX special starts; the owning component spends the bar.
  bool pendingMeterSpend = false;

  final MotionIntent motion = MotionIntent();

  bool _justEntered = true;

  static final Map<FighterState, Set<FighterState>> allowedTransitions = {
    FighterState.idle: {
      FighterState.walkForward, FighterState.walkBackward, FighterState.crouch,
      FighterState.jumpUp, FighterState.jumpForward, FighterState.jumpBackward,
      FighterState.attackLight, FighterState.attackHeavy, FighterState.special,
      FighterState.blockHigh, FighterState.blockLow,
      FighterState.hitstun, FighterState.knockdown, FighterState.airHit,
      FighterState.victory, FighterState.defeat, FighterState.finisher,
    },
    FighterState.walkForward: {
      FighterState.idle, FighterState.walkBackward, FighterState.crouch,
      FighterState.jumpUp, FighterState.jumpForward, FighterState.jumpBackward,
      FighterState.attackLight, FighterState.attackHeavy, FighterState.special,
      FighterState.blockHigh, FighterState.blockLow,
      FighterState.hitstun, FighterState.knockdown, FighterState.airHit,
      FighterState.victory, FighterState.defeat,
    },
    FighterState.walkBackward: {
      FighterState.idle, FighterState.walkForward, FighterState.crouch,
      FighterState.jumpUp, FighterState.jumpForward, FighterState.jumpBackward,
      FighterState.attackLight, FighterState.attackHeavy, FighterState.special,
      FighterState.blockHigh, FighterState.blockLow,
      FighterState.hitstun, FighterState.knockdown, FighterState.airHit,
      FighterState.victory, FighterState.defeat,
    },
    FighterState.crouch: {
      FighterState.idle, FighterState.blockLow, FighterState.attackHeavy,
      FighterState.crouchHitstun, FighterState.knockdown, FighterState.airHit,
      FighterState.victory, FighterState.defeat,
    },
    FighterState.jumpUp: {FighterState.idle, FighterState.airHit, FighterState.defeat},
    FighterState.jumpForward: {FighterState.idle, FighterState.airHit, FighterState.defeat},
    FighterState.jumpBackward: {FighterState.idle, FighterState.airHit, FighterState.defeat},
    FighterState.attackLight: {
      FighterState.idle, FighterState.crouch,
      FighterState.attackLight, FighterState.attackHeavy, FighterState.special,
      FighterState.hitstun, FighterState.crouchHitstun,
      FighterState.knockdown, FighterState.airHit, FighterState.defeat,
    },
    FighterState.attackHeavy: {
      FighterState.idle, FighterState.crouch, FighterState.special,
      FighterState.hitstun, FighterState.crouchHitstun,
      FighterState.knockdown, FighterState.airHit, FighterState.defeat,
    },
    FighterState.special: {
      FighterState.idle, FighterState.crouch,
      FighterState.hitstun, FighterState.crouchHitstun,
      FighterState.knockdown, FighterState.airHit, FighterState.defeat,
    },
    FighterState.blockHigh: {
      FighterState.idle, FighterState.crouch, FighterState.blockLow,
      FighterState.hitstun, FighterState.knockdown, FighterState.airHit,
      FighterState.defeat,
    },
    FighterState.blockLow: {
      FighterState.idle, FighterState.crouch, FighterState.blockHigh,
      FighterState.crouchHitstun, FighterState.knockdown, FighterState.airHit,
      FighterState.defeat,
    },
    FighterState.hitstun: {
      FighterState.idle, FighterState.crouch, FighterState.hitstun,
      FighterState.knockdown, FighterState.airHit, FighterState.defeat,
    },
    FighterState.crouchHitstun: {
      FighterState.idle, FighterState.crouch, FighterState.crouchHitstun,
      FighterState.knockdown, FighterState.airHit, FighterState.defeat,
    },
    FighterState.airHit: {FighterState.airHit, FighterState.knockdown, FighterState.defeat},
    FighterState.knockdown: {FighterState.getUp, FighterState.defeat},
    FighterState.getUp: {FighterState.idle, FighterState.defeat},
    FighterState.victory: {},
    FighterState.defeat: {},
    FighterState.finisher: {FighterState.victory},
  };

  bool get isInvulnerable =>
      state == FighterState.knockdown || state == FighterState.getUp;

  /// Attempts a table-validated transition. Returns false when illegal.
  bool trySetState(FighterState next) {
    if (next == state && !next.isStunned) return false;
    final allowed = allowedTransitions[state] ?? const <FighterState>{};
    if (next != state && !allowed.contains(next)) return false;
    _enter(next);
    return true;
  }

  /// Unvalidated transition for round resets and scripted flow.
  void forceState(FighterState next) => _enter(next);

  /// Full reset between rounds: back to idle, stun and KO cleared.
  void resetForRound(Facing newFacing) {
    facing = newFacing;
    stunTicksRemaining = 0;
    koFlag = false;
    motion.reset();
    forceState(FighterState.idle);
  }

  void _enter(FighterState next) {
    state = next;
    stateTick = 0;
    _justEntered = true;
    if (!next.isAttacking) {
      currentMove = null;
      moveHasConnected = false;
    }
  }

  /// Advances one logic tick. [grounded] reflects the physics state before
  /// this tick; landing is reported separately via [onLanded].
  void tick(InputSnapshot input, InputBuffer buffer) {
    motion.reset();
    if (_justEntered) {
      _justEntered = false;
    } else {
      stateTick++;
    }

    switch (state) {
      case FighterState.idle:
      case FighterState.walkForward:
      case FighterState.walkBackward:
        _tickNeutralStanding(input, buffer);
      case FighterState.crouch:
        _tickCrouch(input, buffer);
      case FighterState.jumpUp:
      case FighterState.jumpForward:
      case FighterState.jumpBackward:
        break; // Airborne: physics drives; landing handled in onLanded.
      case FighterState.attackLight:
      case FighterState.attackHeavy:
      case FighterState.special:
        _tickAttack(input, buffer);
      case FighterState.blockHigh:
      case FighterState.blockLow:
        _tickBlock(input);
      case FighterState.hitstun:
      case FighterState.crouchHitstun:
        _tickHitstun(input);
      case FighterState.airHit:
        break; // Falls until onLanded -> knockdown.
      case FighterState.knockdown:
        _tickKnockdown();
      case FighterState.getUp:
        _tickGetUp();
      case FighterState.victory:
      case FighterState.defeat:
      case FighterState.finisher:
        break;
    }
  }

  void _tickNeutralStanding(InputSnapshot input, InputBuffer buffer) {
    if (input.block) {
      trySetState(input.down ? FighterState.blockLow : FighterState.blockHigh);
      return;
    }
    if (_tryStartSpecial(buffer)) return;
    if (_tryStartBufferedAttack(input, buffer)) return;
    final forward = facing == Facing.right ? input.right : input.left;
    final backward = facing == Facing.right ? input.left : input.right;
    if (input.up) {
      final jumpState = forward
          ? FighterState.jumpForward
          : backward
              ? FighterState.jumpBackward
              : FighterState.jumpUp;
      if (trySetState(jumpState)) {
        motion.startJump = true;
        motion.jumpVelocityX = forward
            ? facing.sign
            : backward
                ? -facing.sign
                : 0;
      }
      return;
    }
    if (input.down) {
      trySetState(FighterState.crouch);
      return;
    }
    if (forward && !backward) {
      trySetState(FighterState.walkForward);
      motion.velocityX = data.walkForwardSpeed * facing.sign;
    } else if (backward && !forward) {
      trySetState(FighterState.walkBackward);
      motion.velocityX = -data.walkBackwardSpeed * facing.sign;
    } else {
      trySetState(FighterState.idle);
    }
  }

  void _tickCrouch(InputSnapshot input, InputBuffer buffer) {
    if (input.block && input.down) {
      trySetState(FighterState.blockLow);
      return;
    }
    // The uppercut is the one attack allowed out of a crouch.
    final uppercutId = data.uppercutMoveId;
    if (uppercutId != null) {
      final uppercut = data.moveById(uppercutId);
      if (buffer.consumePress(BufferedButton.heavy,
          leniencyTicks: uppercut.inputBufferLeniency)) {
        startMove(uppercut);
        return;
      }
    }
    if (!input.down) trySetState(FighterState.idle);
  }

  void _tickAttack(InputSnapshot input, InputBuffer buffer) {
    final move = currentMove;
    if (move == null) {
      trySetState(FighterState.idle);
      return;
    }
    for (final rule in move.cancelInto) {
      if (!rule.isOpenAt(stateTick, hasConnected: moveHasConnected)) continue;
      final target = data.moveById(rule.targetMoveId);
      final button = switch (target.strength) {
        MoveStrength.light => BufferedButton.light,
        MoveStrength.heavy => BufferedButton.heavy,
        MoveStrength.special => BufferedButton.special,
      };
      if (buffer.consumePress(button, leniencyTicks: target.inputBufferLeniency)) {
        startMove(target);
        return;
      }
    }
    if (stateTick >= move.totalTicks - 1) {
      trySetState(input.down ? FighterState.crouch : FighterState.idle);
      // The tick a move ends is already actionable: fire buffered attacks
      // now instead of next tick (keeps input latency under 2 ticks).
      if (state == FighterState.idle) {
        _tryStartBufferedAttack(input, buffer);
      }
    }
  }

  void _tickBlock(InputSnapshot input) {
    if (stunTicksRemaining > 0) {
      stunTicksRemaining--;
      return;
    }
    if (!input.block) {
      trySetState(input.down ? FighterState.crouch : FighterState.idle);
      return;
    }
    trySetState(input.down ? FighterState.blockLow : FighterState.blockHigh);
  }

  void _tickHitstun(InputSnapshot input) {
    if (stunTicksRemaining > 0) {
      stunTicksRemaining--;
      return;
    }
    trySetState(input.down ? FighterState.crouch : FighterState.idle);
  }

  void _tickKnockdown() {
    final anim = data.animationByKey(data.stateAnimation[FighterState.knockdown]!);
    if (stateTick >= anim.totalTicks) {
      if (koFlag) {
        forceState(FighterState.defeat);
      } else {
        trySetState(FighterState.getUp);
      }
    }
  }

  void _tickGetUp() {
    final anim = data.animationByKey(data.stateAnimation[FighterState.getUp]!);
    if (stateTick >= anim.totalTicks) trySetState(FighterState.idle);
  }

  /// Starts the special on a SPECIAL press or quarter-circle-forward +
  /// punch. With a meter bar banked the EX version comes out instead.
  bool _tryStartSpecial(InputBuffer buffer) {
    final specialId = data.specialMoveId;
    if (specialId == null) return false;
    var triggered = buffer.consumePress(BufferedButton.special);
    if (!triggered &&
        MotionParser.hasQuarterCircleForward(buffer.history, facing) &&
        buffer.consumePress(BufferedButton.light)) {
      triggered = true;
    }
    if (!triggered) return false;
    final exId = data.specialExMoveId;
    if (exId != null && meterBars >= 1) {
      startMove(data.moveById(exId));
      pendingMeterSpend = true;
    } else {
      startMove(data.moveById(specialId));
    }
    return true;
  }

  bool _tryStartBufferedAttack(InputSnapshot input, InputBuffer buffer) {
    final light = data.moveById(data.lightStarterMoveId);
    if (buffer.consumePress(BufferedButton.light,
        leniencyTicks: light.inputBufferLeniency)) {
      startMove(light);
      return true;
    }
    // Down + heavy is the uppercut; plain heavy is the heavy starter.
    final heavyId = input.down && data.uppercutMoveId != null
        ? data.uppercutMoveId!
        : data.heavyStarterMoveId;
    final heavy = data.moveById(heavyId);
    if (buffer.consumePress(BufferedButton.heavy,
        leniencyTicks: heavy.inputBufferLeniency)) {
      startMove(heavy);
      return true;
    }
    return false;
  }

  /// Begins [move], entering its attack state. Used for both fresh attacks
  /// and cancels.
  void startMove(MoveData move) {
    final targetState = switch (move.strength) {
      MoveStrength.light => FighterState.attackLight,
      MoveStrength.heavy => FighterState.attackHeavy,
      MoveStrength.special => FighterState.special,
    };
    forceState(targetState);
    currentMove = move;
    moveHasConnected = false;
  }

  /// Called by the match layer when this fighter's attack connects.
  void notifyConnected() => moveHasConnected = true;

  /// Called by physics when the fighter touches the floor.
  void onLanded() {
    if (state.isAirborne) {
      trySetState(
          state == FighterState.airHit ? FighterState.knockdown : FighterState.idle);
    }
  }

  /// Applies an incoming [HitEvent]. The component applies positional
  /// pushback/knockback; this updates state and stun counters.
  void receiveHit(HitEvent event, {required bool airborne}) {
    if (event.blocked) {
      stunTicksRemaining = event.stunTicks;
      return; // Stays in current block state.
    }
    if (airborne || (event.knocksDown && event.knockbackY != 0)) {
      forceState(FighterState.airHit);
      return;
    }
    if (event.knocksDown) {
      forceState(FighterState.knockdown);
      return;
    }
    stunTicksRemaining = event.stunTicks;
    forceState(state.isCrouching ? FighterState.crouchHitstun : FighterState.hitstun);
  }
}
