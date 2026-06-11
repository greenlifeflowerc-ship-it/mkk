/// Every state a fighter can be in. The combat state machine is the single
/// authority over transitions between these.
enum FighterState {
  idle,
  walkForward,
  walkBackward,
  crouch,
  jumpUp,
  jumpForward,
  jumpBackward,
  attackLight,
  attackHeavy,
  special,
  blockHigh,
  blockLow,
  hitstun,
  crouchHitstun,
  airHit,
  knockdown,
  getUp,
  victory,
  defeat,
  finisher,
}

extension FighterStateQueries on FighterState {
  bool get isAirborne =>
      this == FighterState.jumpUp ||
      this == FighterState.jumpForward ||
      this == FighterState.jumpBackward ||
      this == FighterState.airHit;

  bool get isAttacking =>
      this == FighterState.attackLight ||
      this == FighterState.attackHeavy ||
      this == FighterState.special;

  bool get isBlocking =>
      this == FighterState.blockHigh || this == FighterState.blockLow;

  bool get isStunned =>
      this == FighterState.hitstun ||
      this == FighterState.crouchHitstun ||
      this == FighterState.airHit ||
      this == FighterState.knockdown ||
      this == FighterState.getUp;

  bool get isCrouching =>
      this == FighterState.crouch ||
      this == FighterState.blockLow ||
      this == FighterState.crouchHitstun;

  /// Neutral grounded states: facing may auto-update and new actions may
  /// begin from these.
  bool get isNeutral =>
      this == FighterState.idle ||
      this == FighterState.walkForward ||
      this == FighterState.walkBackward ||
      this == FighterState.crouch;

  /// States the fighter cannot act out of and that end the match flow.
  bool get isMatchEndState =>
      this == FighterState.victory ||
      this == FighterState.defeat ||
      this == FighterState.finisher;
}
