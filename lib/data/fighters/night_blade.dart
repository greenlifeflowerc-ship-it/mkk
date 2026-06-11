import '../../game/fighter/fighter_data.dart';
import 'fighter_kit.dart';

/// Fighter #3: Night Blade - a bare-fisted blade dancer, fastest of the
/// roster but fragile. Special: "Void Bolt" violet projectile. Art: CC0
/// "Martial Hero 3" (LuizMelo), repackaged by tool/import_martial_hero.dart.
FighterData nightBlade() {
  return FighterData(
    id: 'night_blade',
    displayName: 'NIGHT BLADE',
    maxHealth: 900,
    walkForwardSpeed: 470,
    walkBackwardSpeed: 360,
    frameSize: 126,
    spriteFeetY: 81,
    renderScale: 10.5,
    bodyBox: standardBodyBox,
    standingHurtboxes: standardStandingHurtboxes,
    crouchingHurtboxes: standardCrouchingHurtboxes,
    airborneHurtboxes: standardAirborneHurtboxes,
    animations: standardAnimations(),
    stateAnimation: standardStateAnimation(),
    moves: standardMoves(
      specialKind: SpecialKind.projectile,
      lightDamage1: 45,
      lightDamage2: 55,
      heavyDamage: 110,
      lightStartup: 4,
      heavyStartup: 11,
      specialDamage: 85,
      specialExDamage: 120,
      projectileSpeed: 1300,
    ),
    lightStarterMoveId: 'light_punch_1',
    heavyStarterMoveId: 'heavy_kick',
    specialMoveId: 'special',
    specialExMoveId: 'special_ex',
    uppercutMoveId: 'uppercut',
  );
}

