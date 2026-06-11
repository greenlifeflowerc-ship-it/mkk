import '../../game/fighter/fighter_data.dart';
import 'fighter_kit.dart';

/// Fighter #4: Grave Warden - a caped executioner; slow, armored in health,
/// devastating. Special: "Sepulcher Slam" crushing strike. Art: CC0
/// "Fantasy Warrior" (LuizMelo), repackaged by tool/import_martial_hero.dart.
FighterData graveWarden() {
  return FighterData(
    id: 'grave_warden',
    displayName: 'GRAVE WARDEN',
    maxHealth: 1100,
    walkForwardSpeed: 350,
    walkBackwardSpeed: 280,
    frameSize: 162,
    spriteFeetY: 100,
    renderScale: 9.1,
    bodyBox: standardBodyBox,
    standingHurtboxes: standardStandingHurtboxes,
    crouchingHurtboxes: standardCrouchingHurtboxes,
    airborneHurtboxes: standardAirborneHurtboxes,
    animations: standardAnimations(),
    stateAnimation: standardStateAnimation(),
    moves: standardMoves(
      specialKind: SpecialKind.strike,
      lightDamage1: 60,
      lightDamage2: 70,
      heavyDamage: 140,
      lightStartup: 7,
      heavyStartup: 15,
      specialDamage: 150,
      specialExDamage: 200,
    ),
    lightStarterMoveId: 'light_punch_1',
    heavyStarterMoveId: 'heavy_kick',
    specialMoveId: 'special',
    specialExMoveId: 'special_ex',
    uppercutMoveId: 'uppercut',
  );
}

