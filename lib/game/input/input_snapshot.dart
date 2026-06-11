/// Immutable record of all input intents for one logic tick. Held booleans
/// reflect current state; `*Pressed` edges are true only on the tick the
/// button went down.
class InputSnapshot {
  const InputSnapshot({
    this.left = false,
    this.right = false,
    this.up = false,
    this.down = false,
    this.lightAttack = false,
    this.heavyAttack = false,
    this.special = false,
    this.block = false,
    this.lightPressed = false,
    this.heavyPressed = false,
    this.specialPressed = false,
    this.upPressed = false,
  });

  static const InputSnapshot empty = InputSnapshot();

  final bool left;
  final bool right;
  final bool up;
  final bool down;
  final bool lightAttack;
  final bool heavyAttack;
  final bool special;
  final bool block;

  final bool lightPressed;
  final bool heavyPressed;
  final bool specialPressed;
  final bool upPressed;

  /// Derives press edges by comparing held state against [previous].
  factory InputSnapshot.withEdges({
    required bool left,
    required bool right,
    required bool up,
    required bool down,
    required bool lightAttack,
    required bool heavyAttack,
    required bool special,
    required bool block,
    required InputSnapshot previous,
  }) {
    return InputSnapshot(
      left: left,
      right: right,
      up: up,
      down: down,
      lightAttack: lightAttack,
      heavyAttack: heavyAttack,
      special: special,
      block: block,
      lightPressed: lightAttack && !previous.lightAttack,
      heavyPressed: heavyAttack && !previous.heavyAttack,
      specialPressed: special && !previous.special,
      upPressed: up && !previous.up,
    );
  }

  bool get anyDirection => left || right || up || down;
}
