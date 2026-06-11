import 'package:flutter_test/flutter_test.dart';
import 'package:mkc/data/fighters/roster.dart';
import 'package:mkc/game/fighter/fighter_data.dart';
import 'package:mkc/game/fighter/fighter_state.dart';

/// Validates the data-driven fighter contract for every roster member:
/// frame data consistency, animation table completeness, and the asset
/// contract from the master plan.
void main() {
  for (final id in rosterIds) {
    group('fighter contract: $id', () => _fighterContract(fighterDataById(id)));
  }
}

void _fighterContract(FighterData data) {
  group('move frame data', () {
    test('every move has positive phase durations', () {
      for (final move in data.moves.values) {
        expect(move.startup, greaterThanOrEqualTo(0), reason: move.id);
        expect(move.active, greaterThan(0), reason: move.id);
        expect(move.recovery, greaterThanOrEqualTo(0), reason: move.id);
        expect(move.totalTicks, move.startup + move.active + move.recovery);
      }
    });

    test('boxesPerTick covers exactly the active window', () {
      for (final move in data.moves.values) {
        expect(move.boxesPerTick.length, move.active, reason: move.id);
      }
    });

    test('hitboxes exist only inside the active window', () {
      for (final move in data.moves.values) {
        expect(move.hitboxesAt(move.startup - 1), isEmpty, reason: move.id);
        if (move.projectile == null) {
          // Projectile moves carry their threat in the projectile instead.
          expect(move.hitboxesAt(move.startup), isNotEmpty, reason: move.id);
          expect(move.hitboxesAt(move.startup + move.active - 1), isNotEmpty,
              reason: move.id);
        }
        expect(move.hitboxesAt(move.startup + move.active), isEmpty,
            reason: move.id);
      }
    });

    test('projectile moves declare a valid spawn tick', () {
      for (final move in data.moves.values) {
        if (move.projectile == null) continue;
        expect(move.projectileSpawnTick, greaterThanOrEqualTo(0),
            reason: move.id);
        expect(move.projectileSpawnTick, lessThan(move.totalTicks),
            reason: move.id);
      }
    });

    test('move animations reference declared sheets and frame ranges', () {
      for (final move in data.moves.values) {
        final anim = data.animations[move.animation];
        expect(anim, isNotNull, reason: '${move.id} -> ${move.animation}');
        expect(move.animStartFrame, lessThanOrEqualTo(move.animEndFrame));
        expect(move.animEndFrame, lessThan(anim!.frameCount),
            reason: move.id);
      }
    });

    test('cancel rules target existing moves with sane windows', () {
      for (final move in data.moves.values) {
        for (final rule in move.cancelInto) {
          expect(data.moves.containsKey(rule.targetMoveId), isTrue,
              reason: '${move.id} -> ${rule.targetMoveId}');
          expect(rule.fromTick, lessThanOrEqualTo(rule.toTick));
          expect(rule.toTick, lessThan(move.totalTicks));
        }
      }
    });

    test('starter and special moves exist', () {
      expect(data.moves.containsKey(data.lightStarterMoveId), isTrue);
      expect(data.moves.containsKey(data.heavyStarterMoveId), isTrue);
      if (data.specialMoveId != null) {
        expect(data.moves.containsKey(data.specialMoveId), isTrue);
      }
      if (data.specialExMoveId != null) {
        expect(data.moves.containsKey(data.specialExMoveId), isTrue);
      }
    });
  });

  group('animation table', () {
    test('every non-attack state has an animation mapping', () {
      const attackStates = {
        FighterState.attackLight,
        FighterState.attackHeavy,
        FighterState.special,
      };
      for (final state in FighterState.values) {
        if (attackStates.contains(state)) continue;
        expect(data.stateAnimation[state], isNotNull, reason: state.name);
      }
    });

    test('state animation mappings reference declared sheets', () {
      for (final entry in data.stateAnimation.entries) {
        expect(data.animations.containsKey(entry.value), isTrue,
            reason: '${entry.key.name} -> ${entry.value}');
      }
    });

    test('asset contract frame counts match the master plan', () {
      const contract = {
        'idle': 8,
        'walk_forward': 8,
        'walk_backward': 8,
        'crouch': 4,
        'jump_up': 6,
        'jump_forward': 6,
        'punch_combo': 8,
        'kick_combo': 8,
        'special_attack': 12,
        'block_high': 4,
        'block_low': 4,
        'hit': 4,
        'knockdown': 8,
        'get_up': 6,
        'victory': 6,
        'defeat': 6,
        'finisher': 12,
      };
      expect(data.animations.keys.toSet(), contract.keys.toSet());
      for (final entry in contract.entries) {
        expect(data.animations[entry.key]!.frameCount, entry.value,
            reason: entry.key);
      }
    });
  });

  group('stance hurtboxes', () {
    test('crouching profile is lower than standing', () {
      final standingTop = data.standingHurtboxes
          .map((b) => b.top)
          .reduce((a, b) => a < b ? a : b);
      final crouchingTop = data.crouchingHurtboxes
          .map((b) => b.top)
          .reduce((a, b) => a < b ? a : b);
      expect(crouchingTop, greaterThan(standingTop));
    });
  });
}
