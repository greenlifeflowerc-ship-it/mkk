import 'package:flutter_test/flutter_test.dart';
import 'package:mkc/data/fighters/ash_viper.dart';
import 'package:mkc/game/combat/hit_event.dart';
import 'package:mkc/game/fighter/combat_state_machine.dart';
import 'package:mkc/game/fighter/fighter_state.dart';
import 'package:mkc/game/input/input_buffer.dart';
import 'package:mkc/game/input/input_snapshot.dart';

/// Drives the FSM exactly like FighterComponent does: push the snapshot,
/// then tick.
class _Harness {
  _Harness() : fsm = CombatStateMachine(ashViper());

  final CombatStateMachine fsm;
  final InputBuffer buffer = InputBuffer();
  int tick = 0;

  void step([InputSnapshot snapshot = InputSnapshot.empty]) {
    buffer.push(snapshot, tick);
    fsm.tick(snapshot, buffer);
    tick++;
  }

  void stepN(int n, [InputSnapshot snapshot = InputSnapshot.empty]) {
    for (var i = 0; i < n; i++) {
      step(snapshot);
    }
  }
}

HitEvent _hit({int stun = 14, bool knocksDown = false, bool blocked = false}) {
  final move = ashViper().moveById('light_punch_1');
  return HitEvent(
    attackerId: 'P2',
    defenderId: 'P1',
    move: move,
    blocked: blocked,
    damage: 50,
    stunTicks: stun,
    pushback: 60,
    knockbackX: 0,
    knockbackY: 0,
    knocksDown: knocksDown,
    hitstopTicks: 4,
    meterGain: 0,
    defenderWasAirborne: false,
  );
}

void main() {
  test('starts idle', () {
    final h = _Harness();
    h.step();
    expect(h.fsm.state, FighterState.idle);
  });

  group('movement', () {
    test('forward input walks forward, backward walks backward', () {
      final h = _Harness(); // Facing right by default.
      h.step(const InputSnapshot(right: true));
      expect(h.fsm.state, FighterState.walkForward);
      expect(h.fsm.motion.velocityX, greaterThan(0));

      h.step(const InputSnapshot(left: true));
      expect(h.fsm.state, FighterState.walkBackward);
      expect(h.fsm.motion.velocityX, lessThan(0));

      h.step();
      expect(h.fsm.state, FighterState.idle);
    });

    test('down crouches and releases back to idle', () {
      final h = _Harness();
      h.step(const InputSnapshot(down: true));
      expect(h.fsm.state, FighterState.crouch);
      h.step();
      expect(h.fsm.state, FighterState.idle);
    });

    test('up jumps with directional variants', () {
      final h = _Harness();
      h.step(const InputSnapshot(up: true, right: true));
      expect(h.fsm.state, FighterState.jumpForward);
      expect(h.fsm.motion.startJump, isTrue);
      expect(h.fsm.motion.jumpVelocityX, greaterThan(0));

      h.fsm.onLanded();
      expect(h.fsm.state, FighterState.idle);
    });
  });

  group('transition table', () {
    test('illegal transitions are rejected', () {
      final h = _Harness();
      h.step(const InputSnapshot(down: true));
      expect(h.fsm.state, FighterState.crouch);
      expect(h.fsm.trySetState(FighterState.attackLight), isFalse);
      expect(h.fsm.state, FighterState.crouch);
    });

    test('defeat is terminal', () {
      final h = _Harness();
      h.fsm.forceState(FighterState.defeat);
      expect(h.fsm.trySetState(FighterState.idle), isFalse);
    });
  });

  group('attacks', () {
    test('light press starts light_punch_1', () {
      final h = _Harness();
      h.step(const InputSnapshot(lightAttack: true, lightPressed: true));
      expect(h.fsm.state, FighterState.attackLight);
      expect(h.fsm.currentMove!.id, 'light_punch_1');
      expect(h.fsm.stateTick, 0);
    });

    test('attacks cannot be interrupted by movement', () {
      final h = _Harness();
      h.step(const InputSnapshot(lightAttack: true, lightPressed: true));
      h.stepN(4, const InputSnapshot(right: true));
      expect(h.fsm.state, FighterState.attackLight);
      expect(h.fsm.currentMove!.id, 'light_punch_1');
    });

    test('move ends into idle after total ticks', () {
      final h = _Harness();
      h.step(const InputSnapshot(lightAttack: true, lightPressed: true));
      final total = h.fsm.currentMove!.totalTicks;
      h.stepN(total);
      expect(h.fsm.state, FighterState.idle);
    });

    test('buffered press during an attack executes on the first legal tick',
        () {
      final h = _Harness();
      h.step(const InputSnapshot(heavyAttack: true, heavyPressed: true));
      expect(h.fsm.state, FighterState.attackHeavy);
      final total = h.fsm.currentMove!.totalTicks;
      // Press light 3 ticks before recovery ends; heavy kick has no light
      // cancel, so it must come out as a fresh move the tick the kick ends.
      h.stepN(total - 4);
      h.step(const InputSnapshot(lightAttack: true, lightPressed: true));
      h.stepN(3);
      expect(h.fsm.state, FighterState.attackLight);
      expect(h.fsm.currentMove!.id, 'light_punch_1');
    });
  });

  group('cancel windows', () {
    test('light_punch_1 cancels into light_punch_2 inside ticks 6-12', () {
      final h = _Harness();
      h.step(const InputSnapshot(lightAttack: true, lightPressed: true));
      h.stepN(6); // stateTick now 6 — window open.
      h.step(const InputSnapshot(lightAttack: true, lightPressed: true));
      expect(h.fsm.state, FighterState.attackLight);
      expect(h.fsm.currentMove!.id, 'light_punch_2');
    });

    test('press after the cancel window does not chain', () {
      final h = _Harness();
      h.step(const InputSnapshot(lightAttack: true, lightPressed: true));
      final lp1 = h.fsm.currentMove!;
      final window = lp1.cancelInto.single.toTick;
      h.stepN(window + 1); // Past the cancel window.
      h.step(const InputSnapshot(lightAttack: true, lightPressed: true));
      expect(h.fsm.currentMove!.id, 'light_punch_1',
          reason: 'chain must not happen outside the window');
    });
  });

  group('blocking', () {
    test('block button gives high block standing, low block crouching', () {
      final h = _Harness();
      h.step(const InputSnapshot(block: true));
      expect(h.fsm.state, FighterState.blockHigh);
      h.step(const InputSnapshot(block: true, down: true));
      expect(h.fsm.state, FighterState.blockLow);
      h.step();
      expect(h.fsm.state, FighterState.idle);
    });

    test('blockstun locks the block until it expires', () {
      final h = _Harness();
      h.step(const InputSnapshot(block: true));
      h.fsm.receiveHit(_hit(blocked: true, stun: 5), airborne: false);
      expect(h.fsm.state, FighterState.blockHigh);
      // Release block immediately: still stuck for the stun duration.
      h.stepN(5);
      expect(h.fsm.state, FighterState.blockHigh);
      h.step();
      expect(h.fsm.state, FighterState.idle);
    });
  });

  group('hitstun and knockdown', () {
    test('hitstun exits to idle after stun ticks', () {
      final h = _Harness();
      h.step();
      h.fsm.receiveHit(_hit(stun: 10), airborne: false);
      expect(h.fsm.state, FighterState.hitstun);
      h.stepN(10);
      expect(h.fsm.state, FighterState.hitstun);
      h.step();
      expect(h.fsm.state, FighterState.idle);
    });

    test('nothing cancels hitstun', () {
      final h = _Harness();
      h.step();
      h.fsm.receiveHit(_hit(stun: 10), airborne: false);
      h.step(const InputSnapshot(lightAttack: true, lightPressed: true));
      expect(h.fsm.state, FighterState.hitstun);
      expect(h.fsm.trySetState(FighterState.walkForward), isFalse);
    });

    test('grounded knockdown runs knockdown -> getUp -> idle', () {
      final h = _Harness();
      h.step();
      h.fsm.receiveHit(_hit(knocksDown: true), airborne: false);
      expect(h.fsm.state, FighterState.knockdown);
      final knockdownTicks =
          h.fsm.data.animationByKey('knockdown').totalTicks;
      h.stepN(knockdownTicks + 1);
      expect(h.fsm.state, FighterState.getUp);
      expect(h.fsm.isInvulnerable, isTrue);
      final getUpTicks = h.fsm.data.animationByKey('get_up').totalTicks;
      h.stepN(getUpTicks + 1);
      expect(h.fsm.state, FighterState.idle);
    });

    test('KO during knockdown ends in defeat', () {
      final h = _Harness();
      h.step();
      h.fsm.koFlag = true;
      h.fsm.receiveHit(_hit(knocksDown: true), airborne: false);
      final knockdownTicks =
          h.fsm.data.animationByKey('knockdown').totalTicks;
      h.stepN(knockdownTicks + 1);
      expect(h.fsm.state, FighterState.defeat);
    });

    test('air hit lands into knockdown', () {
      final h = _Harness();
      h.step(const InputSnapshot(up: true));
      expect(h.fsm.state, FighterState.jumpUp);
      h.fsm.receiveHit(_hit(), airborne: true);
      expect(h.fsm.state, FighterState.airHit);
      h.fsm.onLanded();
      expect(h.fsm.state, FighterState.knockdown);
    });
  });

  group('uppercut', () {
    test('down + heavy from standing launches the uppercut', () {
      final h = _Harness();
      h.step(); // settle in idle
      h.step(const InputSnapshot(
          down: true, heavyAttack: true, heavyPressed: true));
      expect(h.fsm.state, FighterState.attackHeavy);
      expect(h.fsm.currentMove!.id, 'uppercut');
    });

    test('heavy press while crouched launches the uppercut', () {
      final h = _Harness();
      h.step(const InputSnapshot(down: true));
      expect(h.fsm.state, FighterState.crouch);
      h.step(const InputSnapshot(
          down: true, heavyAttack: true, heavyPressed: true));
      expect(h.fsm.state, FighterState.attackHeavy);
      expect(h.fsm.currentMove!.id, 'uppercut');
    });

    test('plain heavy press stays the heavy starter', () {
      final h = _Harness();
      h.step(const InputSnapshot(heavyAttack: true, heavyPressed: true));
      expect(h.fsm.currentMove!.id, 'heavy_kick');
    });

    test('uppercut launches the defender upward', () {
      final data = ashViper();
      final uppercut = data.moveById('uppercut');
      expect(uppercut.knocksDown, isTrue);
      expect(uppercut.knockbackY, lessThan(-1000));
    });
  });

  group('special moves', () {
    test('special button starts the special move', () {
      final h = _Harness();
      h.step(const InputSnapshot(special: true, specialPressed: true));
      expect(h.fsm.state, FighterState.special);
      expect(h.fsm.currentMove!.id, 'special');
    });

    test('quarter-circle-forward + punch starts the special', () {
      final h = _Harness();
      h.step(const InputSnapshot(down: true));
      h.step(const InputSnapshot(down: true, right: true));
      h.step(const InputSnapshot(right: true));
      h.step(const InputSnapshot(
          right: true, lightAttack: true, lightPressed: true));
      expect(h.fsm.state, FighterState.special);
      expect(h.fsm.currentMove!.id, 'special');
    });

    test('plain light press without the motion stays a normal punch', () {
      final h = _Harness();
      h.step(const InputSnapshot(lightAttack: true, lightPressed: true));
      expect(h.fsm.state, FighterState.attackLight);
      expect(h.fsm.currentMove!.id, 'light_punch_1');
    });

    test('a banked meter bar upgrades the special to EX and spends it', () {
      final h = _Harness();
      h.fsm.meterBars = 1;
      h.step(const InputSnapshot(special: true, specialPressed: true));
      expect(h.fsm.currentMove!.id, 'special_ex');
      expect(h.fsm.pendingMeterSpend, isTrue);
    });
  });
}
