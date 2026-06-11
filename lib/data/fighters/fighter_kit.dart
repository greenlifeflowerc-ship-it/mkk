import '../../game/combat/frame_data.dart';
import '../../game/combat/move_data.dart';
import '../../game/combat/projectile.dart';
import '../../game/fighter/fighter_data.dart';
import '../../game/fighter/fighter_state.dart';

// Shared building blocks for the roster. Every fighter file stays a small
// tuning sheet; the engine still only ever sees plain FighterData.

/// What a fighter's special move does.
enum SpecialKind { projectile, strike }

/// The 17-animation sheet contract every imported pack fulfils.
Map<String, FighterAnimationDef> standardAnimations() => const {
      'idle': FighterAnimationDef(key: 'idle', frameCount: 8, loop: true, ticksPerFrame: 5),
      'walk_forward': FighterAnimationDef(key: 'walk_forward', frameCount: 8, loop: true),
      'walk_backward': FighterAnimationDef(key: 'walk_backward', frameCount: 8, loop: true),
      'crouch': FighterAnimationDef(key: 'crouch', frameCount: 4, holdLast: true, ticksPerFrame: 3),
      'jump_up': FighterAnimationDef(key: 'jump_up', frameCount: 6, holdLast: true),
      'jump_forward': FighterAnimationDef(key: 'jump_forward', frameCount: 6, holdLast: true),
      'punch_combo': FighterAnimationDef(key: 'punch_combo', frameCount: 8),
      'kick_combo': FighterAnimationDef(key: 'kick_combo', frameCount: 8),
      'special_attack': FighterAnimationDef(key: 'special_attack', frameCount: 12),
      'block_high': FighterAnimationDef(key: 'block_high', frameCount: 4, holdLast: true, ticksPerFrame: 3),
      'block_low': FighterAnimationDef(key: 'block_low', frameCount: 4, holdLast: true, ticksPerFrame: 3),
      'hit': FighterAnimationDef(key: 'hit', frameCount: 4, holdLast: true, ticksPerFrame: 3),
      'knockdown': FighterAnimationDef(key: 'knockdown', frameCount: 8),
      'get_up': FighterAnimationDef(key: 'get_up', frameCount: 6),
      'victory': FighterAnimationDef(key: 'victory', frameCount: 6, holdLast: true, ticksPerFrame: 5),
      'defeat': FighterAnimationDef(key: 'defeat', frameCount: 6, holdLast: true),
      'finisher': FighterAnimationDef(key: 'finisher', frameCount: 12),
    };

Map<FighterState, String> standardStateAnimation() => const {
      FighterState.idle: 'idle',
      FighterState.walkForward: 'walk_forward',
      FighterState.walkBackward: 'walk_backward',
      FighterState.crouch: 'crouch',
      FighterState.jumpUp: 'jump_up',
      FighterState.jumpForward: 'jump_forward',
      FighterState.jumpBackward: 'jump_forward',
      FighterState.blockHigh: 'block_high',
      FighterState.blockLow: 'block_low',
      FighterState.hitstun: 'hit',
      FighterState.crouchHitstun: 'hit',
      FighterState.airHit: 'hit',
      FighterState.knockdown: 'knockdown',
      FighterState.getUp: 'get_up',
      FighterState.victory: 'victory',
      FighterState.defeat: 'defeat',
      FighterState.finisher: 'finisher',
    };

/// Standard sword-fighter move set: two-hit light chain, knockdown heavy,
/// and a special (projectile or strike) with an EX upgrade. All boxes are
/// in logical px for a ~400 px tall fighter.
Map<String, MoveData> standardMoves({
  required SpecialKind specialKind,
  int lightDamage1 = 50,
  int lightDamage2 = 60,
  int heavyDamage = 120,
  int lightStartup = 5,
  int heavyStartup = 12,
  int specialDamage = 90,
  int specialExDamage = 130,
  int uppercutDamage = 110,
  double projectileSpeed = 1050,
}) {
  const slashArmHurt = CombatBox(x: 60, y: -420, width: 280, height: 180);

  List<FrameBoxes> repeated(int count, CombatBox hit) => [
        for (var i = 0; i < count; i++)
          FrameBoxes(hurtboxes: const [slashArmHurt], hitboxes: [hit]),
      ];

  final lightPunch1 = MoveData(
    id: 'light_punch_1',
    animation: 'punch_combo',
    animStartFrame: 0,
    animEndFrame: 3,
    startup: lightStartup,
    active: 3,
    recovery: 8,
    damage: lightDamage1,
    hitstun: 14,
    blockstun: 8,
    pushbackHit: 60,
    pushbackBlock: 80,
    strength: MoveStrength.light,
    level: HitLevel.high,
    meterGainOnHit: 60,
    meterGainOnBlock: 20,
    boxesPerTick:
        repeated(3, const CombatBox(x: 80, y: -440, width: 340, height: 220)),
    cancelInto: [
      CancelRule(
          targetMoveId: 'light_punch_2',
          fromTick: lightStartup + 1,
          toTick: lightStartup + 7),
    ],
  );

  final lightPunch2 = MoveData(
    id: 'light_punch_2',
    animation: 'punch_combo',
    animStartFrame: 4,
    animEndFrame: 7,
    startup: lightStartup + 1,
    active: 3,
    recovery: 12,
    damage: lightDamage2,
    hitstun: 16,
    blockstun: 9,
    pushbackHit: 90,
    pushbackBlock: 110,
    strength: MoveStrength.light,
    level: HitLevel.high,
    meterGainOnHit: 60,
    meterGainOnBlock: 20,
    boxesPerTick:
        repeated(3, const CombatBox(x: 90, y: -460, width: 380, height: 240)),
    cancelInto: const [
      CancelRule(
          targetMoveId: 'special',
          fromTick: 8,
          toTick: 16,
          requiresContact: true),
    ],
  );

  final heavyKick = MoveData(
    id: 'heavy_kick',
    animation: 'kick_combo',
    animStartFrame: 0,
    animEndFrame: 7,
    startup: heavyStartup,
    active: 4,
    recovery: 18,
    damage: heavyDamage,
    hitstun: 20,
    blockstun: 14,
    pushbackHit: 0,
    pushbackBlock: 140,
    strength: MoveStrength.heavy,
    level: HitLevel.mid,
    knocksDown: true,
    knockbackX: 520,
    knockbackY: -750,
    meterGainOnHit: 100,
    meterGainOnBlock: 30,
    boxesPerTick:
        repeated(4, const CombatBox(x: 80, y: -430, width: 410, height: 290)),
  );

  // MK-style uppercut: down + heavy. Slow recovery, huge vertical launch.
  final uppercut = MoveData(
    id: 'uppercut',
    animation: 'kick_combo',
    animStartFrame: 0,
    animEndFrame: 5,
    startup: 8,
    active: 4,
    recovery: 26,
    damage: uppercutDamage,
    hitstun: 22,
    blockstun: 12,
    pushbackHit: 0,
    pushbackBlock: 120,
    strength: MoveStrength.heavy,
    level: HitLevel.mid,
    knocksDown: true,
    knockbackX: 220,
    knockbackY: -1150,
    meterGainOnHit: 80,
    meterGainOnBlock: 25,
    boxesPerTick: repeated(
        4, const CombatBox(x: 40, y: -560, width: 260, height: 480)),
  );

  final MoveData special;
  final MoveData specialEx;
  if (specialKind == SpecialKind.projectile) {
    special = MoveData(
      id: 'special',
      animation: 'special_attack',
      animStartFrame: 0,
      animEndFrame: 11,
      startup: 10,
      active: 2,
      recovery: 22,
      damage: 0,
      hitstun: 0,
      blockstun: 0,
      pushbackHit: 0,
      pushbackBlock: 0,
      strength: MoveStrength.special,
      meterGainOnHit: 0,
      meterGainOnBlock: 0,
      boxesPerTick: const [FrameBoxes(), FrameBoxes()],
      projectile: ProjectileData(
        speed: projectileSpeed,
        damage: specialDamage,
        hitstun: 20,
        blockstun: 12,
        pushback: 90,
      ),
      projectileSpawnTick: 10,
    );
    specialEx = MoveData(
      id: 'special_ex',
      animation: 'special_attack',
      animStartFrame: 0,
      animEndFrame: 11,
      startup: 10,
      active: 2,
      recovery: 20,
      damage: 0,
      hitstun: 0,
      blockstun: 0,
      pushbackHit: 0,
      pushbackBlock: 0,
      strength: MoveStrength.special,
      boxesPerTick: const [FrameBoxes(), FrameBoxes()],
      projectile: ProjectileData(
        speed: projectileSpeed * 1.25,
        damage: specialExDamage,
        hitstun: 24,
        blockstun: 14,
        pushback: 120,
        knocksDown: true,
        renderSize: 260,
      ),
      projectileSpawnTick: 10,
    );
  } else {
    special = MoveData(
      id: 'special',
      animation: 'special_attack',
      animStartFrame: 0,
      animEndFrame: 11,
      startup: 12,
      active: 6,
      recovery: 24,
      damage: specialDamage,
      hitstun: 24,
      blockstun: 16,
      pushbackHit: 60,
      pushbackBlock: 150,
      strength: MoveStrength.special,
      knocksDown: true,
      knockbackX: 560,
      knockbackY: -700,
      meterGainOnHit: 0,
      meterGainOnBlock: 0,
      boxesPerTick: repeated(
          6, const CombatBox(x: 70, y: -470, width: 460, height: 330)),
    );
    specialEx = MoveData(
      id: 'special_ex',
      animation: 'special_attack',
      animStartFrame: 0,
      animEndFrame: 11,
      startup: 10,
      active: 8,
      recovery: 22,
      damage: specialExDamage,
      hitstun: 26,
      blockstun: 18,
      pushbackHit: 60,
      pushbackBlock: 170,
      strength: MoveStrength.special,
      knocksDown: true,
      knockbackX: 640,
      knockbackY: -800,
      boxesPerTick: repeated(
          8, const CombatBox(x: 70, y: -490, width: 500, height: 360)),
    );
  }

  return {
    for (final move in [
      lightPunch1, lightPunch2, heavyKick, uppercut, special, specialEx,
    ])
      move.id: move,
  };
}

/// Standard stance boxes for a ~400 px fighter.
const standardBodyBox = CombatBox(x: -55, y: -360, width: 110, height: 360);
const standardStandingHurtboxes = [
  CombatBox(x: -70, y: -410, width: 140, height: 250),
  CombatBox(x: -60, y: -160, width: 120, height: 160),
];
const standardCrouchingHurtboxes = [
  CombatBox(x: -70, y: -260, width: 140, height: 260),
];
const standardAirborneHurtboxes = [
  CombatBox(x: -80, y: -380, width: 160, height: 260),
];
