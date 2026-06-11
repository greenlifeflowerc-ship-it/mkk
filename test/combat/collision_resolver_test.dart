import 'package:flutter_test/flutter_test.dart';
import 'package:mkc/game/combat/collision_resolver.dart';
import 'package:mkc/game/combat/frame_data.dart';
import 'package:mkc/game/combat/move_data.dart';

MoveData _move({
  HitLevel level = HitLevel.mid,
  MoveStrength strength = MoveStrength.light,
  int damage = 50,
  bool knocksDown = false,
}) {
  return MoveData(
    id: 'test_move',
    animation: 'punch_combo',
    animStartFrame: 0,
    animEndFrame: 3,
    startup: 5,
    active: 3,
    recovery: 8,
    damage: damage,
    hitstun: 14,
    blockstun: 8,
    pushbackHit: 60,
    pushbackBlock: 80,
    strength: strength,
    level: level,
    knocksDown: knocksDown,
    boxesPerTick: const [
      FrameBoxes(hitboxes: [CombatBox(x: 60, y: -380, width: 130, height: 90)]),
      FrameBoxes(hitboxes: [CombatBox(x: 60, y: -380, width: 130, height: 90)]),
      FrameBoxes(hitboxes: [CombatBox(x: 60, y: -380, width: 130, height: 90)]),
    ],
  );
}

const _standingHurt = [CombatBox(x: -70, y: -410, width: 140, height: 250)];

CombatantView _attacker(MoveData move,
    {int moveTick = 5, bool facingRight = true, bool hasConnected = false}) {
  return CombatantView(
    id: 'P1',
    x: 1000,
    y: 920,
    facingRight: facingRight,
    move: move,
    moveTick: moveTick,
    moveHasConnected: hasConnected,
    hurtboxes: _standingHurt,
  );
}

CombatantView _defender({
  double x = 1150,
  bool blockingHigh = false,
  bool blockingLow = false,
  bool airborne = false,
  bool invulnerable = false,
}) {
  return CombatantView(
    id: 'P2',
    x: x,
    y: 920,
    facingRight: false,
    hurtboxes: _standingHurt,
    blockingHigh: blockingHigh,
    blockingLow: blockingLow,
    airborne: airborne,
    invulnerable: invulnerable,
  );
}

void main() {
  group('CombatBox overlap math', () {
    test('overlapping boxes report overlap', () {
      const a = CombatBox(x: 0, y: 0, width: 100, height: 100);
      const b = CombatBox(x: 50, y: 50, width: 100, height: 100);
      expect(a.overlaps(b), isTrue);
      expect(b.overlaps(a), isTrue);
    });

    test('edge-touching boxes do not overlap', () {
      const a = CombatBox(x: 0, y: 0, width: 100, height: 100);
      const b = CombatBox(x: 100, y: 0, width: 100, height: 100);
      expect(a.overlaps(b), isFalse);
    });

    test('contained box overlaps', () {
      const outer = CombatBox(x: 0, y: 0, width: 200, height: 200);
      const inner = CombatBox(x: 50, y: 50, width: 20, height: 20);
      expect(outer.overlaps(inner), isTrue);
    });

    test('toWorld mirrors around origin when facing left', () {
      const box = CombatBox(x: 60, y: -380, width: 130, height: 90);
      final right = box.toWorld(1000, 920, facingRight: true);
      final left = box.toWorld(1000, 920, facingRight: false);
      expect(right.left, 1060);
      expect(right.right, 1190);
      expect(left.right, 940);
      expect(left.left, 810);
      expect(left.top, right.top);
    });
  });

  group('hit detection', () {
    test('active hitbox in range connects', () {
      final event = CollisionResolver.checkHit(
          attacker: _attacker(_move()), defender: _defender());
      expect(event, isNotNull);
      expect(event!.blocked, isFalse);
      expect(event.damage, 50);
      expect(event.stunTicks, 14);
    });

    test('no hit outside the active window', () {
      for (final tick in [0, 4, 8, 15]) {
        final event = CollisionResolver.checkHit(
            attacker: _attacker(_move(), moveTick: tick),
            defender: _defender());
        expect(event, isNull, reason: 'tick $tick should not be active');
      }
    });

    test('no hit when out of range', () {
      final event = CollisionResolver.checkHit(
          attacker: _attacker(_move()), defender: _defender(x: 1400));
      expect(event, isNull);
    });

    test('one hit per move activation', () {
      final event = CollisionResolver.checkHit(
          attacker: _attacker(_move(), hasConnected: true),
          defender: _defender());
      expect(event, isNull);
    });

    test('invulnerable defender cannot be hit', () {
      final event = CollisionResolver.checkHit(
          attacker: _attacker(_move()),
          defender: _defender(invulnerable: true));
      expect(event, isNull);
    });

    test('mirrored attacker hits a defender on its left', () {
      final attacker = CombatantView(
        id: 'P1',
        x: 1000,
        y: 920,
        facingRight: false,
        move: _move(),
        moveTick: 5,
        hurtboxes: _standingHurt,
      );
      final event = CollisionResolver.checkHit(
          attacker: attacker, defender: _defender(x: 850));
      expect(event, isNotNull);
      expect(event!.pushback, isNegative);
    });

    test('pushback is signed away from the attacker', () {
      final event = CollisionResolver.checkHit(
          attacker: _attacker(_move()), defender: _defender());
      expect(event!.pushback, isPositive);
    });

    test('grounded hit with knockdown flags knocksDown', () {
      final event = CollisionResolver.checkHit(
          attacker: _attacker(_move(knocksDown: true)), defender: _defender());
      expect(event!.knocksDown, isTrue);
    });

    test('airborne defender always falls on hit', () {
      final event = CollisionResolver.checkHit(
          attacker: _attacker(_move()), defender: _defender(airborne: true));
      expect(event!.knocksDown, isTrue);
      expect(event.defenderWasAirborne, isTrue);
    });
  });

  group('block-level matrix', () {
    bool blocked(HitLevel level,
        {bool blockingHigh = false, bool blockingLow = false}) {
      final event = CollisionResolver.checkHit(
        attacker: _attacker(_move(level: level)),
        defender:
            _defender(blockingHigh: blockingHigh, blockingLow: blockingLow),
      );
      return event!.blocked;
    }

    test('high: standing block only', () {
      expect(blocked(HitLevel.high, blockingHigh: true), isTrue);
      expect(blocked(HitLevel.high, blockingLow: true), isFalse);
    });

    test('mid: either block', () {
      expect(blocked(HitLevel.mid, blockingHigh: true), isTrue);
      expect(blocked(HitLevel.mid, blockingLow: true), isTrue);
    });

    test('low: crouching block only', () {
      expect(blocked(HitLevel.low, blockingHigh: true), isFalse);
      expect(blocked(HitLevel.low, blockingLow: true), isTrue);
    });

    test('overhead: standing block only', () {
      expect(blocked(HitLevel.overhead, blockingHigh: true), isTrue);
      expect(blocked(HitLevel.overhead, blockingLow: true), isFalse);
    });

    test('no block stance at all gets hit', () {
      expect(blocked(HitLevel.mid), isFalse);
    });

    test('airborne defender cannot block', () {
      final event = CollisionResolver.checkHit(
        attacker: _attacker(_move(level: HitLevel.mid)),
        defender: _defender(blockingHigh: true, airborne: true),
      );
      expect(event!.blocked, isFalse);
    });
  });

  group('chip damage', () {
    test('blocked special chips 15%, normals chip nothing', () {
      final special = CollisionResolver.checkHit(
        attacker: _attacker(
            _move(strength: MoveStrength.special, damage: 100)),
        defender: _defender(blockingHigh: true),
      );
      expect(special!.blocked, isTrue);
      expect(special.damage, 15);

      final normal = CollisionResolver.checkHit(
        attacker: _attacker(_move(damage: 100)),
        defender: _defender(blockingHigh: true),
      );
      expect(normal!.blocked, isTrue);
      expect(normal.damage, 0);
      expect(normal.stunTicks, 8); // blockstun, not hitstun
    });
  });
}
