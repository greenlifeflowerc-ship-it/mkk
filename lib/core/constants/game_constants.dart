/// Global gameplay tuning constants. All gameplay math lives in logical
/// 1920x1080 space and is expressed in logical pixels and 60 Hz ticks.
class GameConstants {
  GameConstants._();

  // Resolution.
  static const double logicalWidth = 1920;
  static const double logicalHeight = 1080;

  // Fixed timestep.
  static const int ticksPerSecond = 60;
  static const double tickSeconds = 1.0 / ticksPerSecond;

  // Physics (logical px / s and px / s^2).
  static const double gravity = 3600;
  static const double jumpVelocityY = -1400;
  static const double jumpVelocityX = 450;

  // Stage geometry.
  static const double floorY = 920;
  static const double stageLeftBound = 0;
  static const double stageRightBound = 2800;

  // Match.
  static const int maxHealth = 1000;
  static const int roundTimerSeconds = 99;
  static const int roundsToWin = 2;

  // Game feel.
  static const int hitstopLightTicks = 4;
  static const int hitstopHeavyTicks = 7;
  static const int hitstopSpecialTicks = 10;
  static const double koSlowmoRate = 0.4;
  static const int koSlowmoTicks = 90;

  // Input.
  static const int inputBufferTicks = 10;
  static const int defaultInputLeniencyTicks = 6;

  /// Window for special-move motion commands (e.g. down, down-forward,
  /// forward + punch).
  static const int motionWindowTicks = 18;

  // Combat rules.
  static const double chipDamageRatio = 0.15;
  static const List<double> comboDamageScaling = [1.0, 0.9, 0.8, 0.7, 0.6];
  static const double comboDamageScalingFloor = 0.5;

  // Fighter spawn offsets from stage center.
  static const double spawnOffsetX = 500;
}
