import '../../game/fighter/fighter_data.dart';
import 'fighter_kit.dart';

/// Fighter #2: Iron Ghost - a masked swordsman in indigo robes; slower but
/// harder-hitting. Special: "Oni Rush" lunging strike. Art: CC0 "Martial
/// Hero 2" (LuizMelo), repackaged by tool/import_martial_hero.dart.
FighterData ironGhost() {
  return FighterData(
    id: 'iron_ghost',
    displayName: 'IRON GHOST',
    maxHealth: 1000,
    walkForwardSpeed: 390,
    walkBackwardSpeed: 310,
    frameSize: 200,
    spriteFeetY: 127,
    renderScale: 7.5,
    bodyBox: standardBodyBox,
    standingHurtboxes: standardStandingHurtboxes,
    crouchingHurtboxes: standardCrouchingHurtboxes,
    airborneHurtboxes: standardAirborneHurtboxes,
    animations: standardAnimations(),
    stateAnimation: standardStateAnimation(),
    moves: standardMoves(
      specialKind: SpecialKind.strike,
      lightDamage1: 55,
      lightDamage2: 65,
      heavyDamage: 135,
      lightStartup: 6,
      heavyStartup: 14,
      specialDamage: 140,
      specialExDamage: 190,
    ),
    lightStarterMoveId: 'light_punch_1',
    heavyStarterMoveId: 'heavy_kick',
    specialMoveId: 'special',
    specialExMoveId: 'special_ex',
    uppercutMoveId: 'uppercut',
  );
}

