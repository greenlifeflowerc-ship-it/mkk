import '../../game/fighter/fighter_data.dart';
import 'fighter_kit.dart';

/// Fighter #5: Void Drake - a spectral dragon ninja in black and violet.
/// Special: "Void Fang" shadow-dragon projectile. Art: AI-generated original
/// set (Higgsfield), repackaged by tool/import_void_drake.dart.
FighterData voidDrake() {
  return FighterData(
    id: 'void_drake',
    displayName: 'VOID DRAKE',
    maxHealth: 1000,
    walkForwardSpeed: 450,
    walkBackwardSpeed: 350,
    frameSize: 320,
    spriteFeetY: 290,
    renderScale: 1.74,
    bodyBox: standardBodyBox,
    standingHurtboxes: standardStandingHurtboxes,
    crouchingHurtboxes: standardCrouchingHurtboxes,
    airborneHurtboxes: standardAirborneHurtboxes,
    animations: standardAnimations(),
    stateAnimation: standardStateAnimation(),
    moves: standardMoves(
      specialKind: SpecialKind.projectile,
      lightDamage1: 50,
      lightDamage2: 65,
      heavyDamage: 115,
      specialDamage: 95,
      specialExDamage: 140,
      projectileSpeed: 1250,
    ),
    lightStarterMoveId: 'light_punch_1',
    heavyStarterMoveId: 'heavy_kick',
    specialMoveId: 'special',
    specialExMoveId: 'special_ex',
    uppercutMoveId: 'uppercut',
  );
}
