import '../../game/fighter/fighter_data.dart';
import 'fighter_kit.dart';

/// Fighter #1: Ash Viper - a fast, wiry ronin under a straw kasa hat.
/// Special: "Ember Fang" amber projectile. Art: CC0 "Martial Hero"
/// (LuizMelo), repackaged by tool/import_martial_hero.dart.
FighterData ashViper() {
  return FighterData(
    id: 'ash_viper',
    displayName: 'ASH VIPER',
    maxHealth: 1000,
    walkForwardSpeed: 420,
    walkBackwardSpeed: 330,
    frameSize: 200,
    spriteFeetY: 121,
    renderScale: 7.8,
    bodyBox: standardBodyBox,
    standingHurtboxes: standardStandingHurtboxes,
    crouchingHurtboxes: standardCrouchingHurtboxes,
    airborneHurtboxes: standardAirborneHurtboxes,
    animations: standardAnimations(),
    stateAnimation: standardStateAnimation(),
    moves: standardMoves(
      specialKind: SpecialKind.projectile,
      lightDamage1: 50,
      lightDamage2: 60,
      heavyDamage: 120,
      specialDamage: 90,
      specialExDamage: 130,
      projectileSpeed: 1100,
    ),
    lightStarterMoveId: 'light_punch_1',
    heavyStarterMoveId: 'heavy_kick',
    specialMoveId: 'special',
    specialExMoveId: 'special_ex',
    uppercutMoveId: 'uppercut',
  );
}

