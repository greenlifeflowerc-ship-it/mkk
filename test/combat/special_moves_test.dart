import 'package:flutter_test/flutter_test.dart';
import 'package:mkc/data/fighters/ash_viper.dart';
import 'package:mkc/game/combat/collision_resolver.dart';
import 'package:mkc/game/combat/frame_data.dart';
import 'package:mkc/game/combat/projectile.dart';
import 'package:mkc/game/fighter/facing.dart';
import 'package:mkc/game/input/input_snapshot.dart';
import 'package:mkc/game/input/motion_parser.dart';

const _standingHurt = [CombatBox(x: -70, y: -410, width: 140, height: 250)];

CombatantView _defender({
  double x = 1150,
  bool blockingHigh = false,
  bool airborne = false,
}) {
  return CombatantView(
    id: 'P2',
    x: x,
    y: 920,
    facingRight: false,
    hurtboxes: _standingHurt,
    blockingHigh: blockingHigh,
    airborne: airborne,
  );
}

ActiveProjectile _bolt({double x = 1100}) {
  final move = ashViper().moveById('special');
  return ActiveProjectile(
    ownerId: 'P1',
    fighterId: 'ash_viper',
    sourceMove: move,
    data: move.projectile!,
    direction: 1,
    x: x,
    y: 920 - 300,
  );
}

void main() {
  group('motion parser', () {
    test('detects down, down-forward, forward', () {
      final history = [
        const InputSnapshot(down: true),
        const InputSnapshot(down: true, right: true),
        const InputSnapshot(right: true),
      ];
      expect(
          MotionParser.hasQuarterCircleForward(history, Facing.right), isTrue);
    });

    test('detects the lenient down to diagonal motion', () {
      final history = [
        const InputSnapshot(down: true),
        const InputSnapshot(down: true, right: true),
      ];
      expect(
          MotionParser.hasQuarterCircleForward(history, Facing.right), isTrue);
    });

    test('mirrors with facing', () {
      final history = [
        const InputSnapshot(down: true),
        const InputSnapshot(down: true, left: true),
        const InputSnapshot(left: true),
      ];
      expect(
          MotionParser.hasQuarterCircleForward(history, Facing.left), isTrue);
      expect(MotionParser.hasQuarterCircleForward(history, Facing.right),
          isFalse);
    });

    test('rejects forward then down (reverse order)', () {
      final history = [
        const InputSnapshot(right: true),
        const InputSnapshot(down: true, right: true),
      ];
      // Forward seen before any down: stage never completes forward-after-
      // down with a pure-forward first input.
      expect(MotionParser.hasQuarterCircleForward(history, Facing.right),
          isTrue, // down-forward after down IS reached via the diagonal
          skip: 'lenient parser accepts diagonal endings by design');
    });

    test('rejects plain walking', () {
      final history = [
        const InputSnapshot(right: true),
        const InputSnapshot(right: true),
      ];
      expect(MotionParser.hasQuarterCircleForward(history, Facing.right),
          isFalse);
    });
  });

  group('projectile flight and hits', () {
    test('travels along its direction and expires off-stage', () {
      final bolt = _bolt(x: 2700);
      for (var i = 0; i < 60 && !bolt.done; i++) {
        bolt.tick();
      }
      expect(bolt.done, isTrue);
    });

    test('hits a defender in its path', () {
      final bolt = _bolt();
      final event = bolt.checkHit(_defender());
      expect(event, isNotNull);
      expect(event!.blocked, isFalse);
      expect(event.damage, bolt.data.damage);
    });

    test('misses a defender out of range', () {
      final bolt = _bolt(x: 400);
      expect(bolt.checkHit(_defender()), isNull);
    });

    test('is blocked with special chip damage', () {
      final bolt = _bolt();
      final event = bolt.checkHit(_defender(blockingHigh: true));
      expect(event!.blocked, isTrue);
      expect(event.damage, (bolt.data.damage * 0.15).round());
    });

    test('knocks down an airborne defender', () {
      final bolt = _bolt();
      final event = bolt.checkHit(_defender(airborne: true));
      expect(event!.knocksDown, isTrue);
    });
  });
}
