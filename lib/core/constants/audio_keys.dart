/// Audio asset keys. Wired up in Phase 7; declared here so gameplay code can
/// reference stable identifiers from day one.
class AudioKeys {
  AudioKeys._();

  static const String hitLight = 'sfx/hit_light.wav';
  static const String hitHeavy = 'sfx/hit_heavy.wav';
  static const String blockImpact = 'sfx/block.wav';
  static const String whoosh = 'sfx/whoosh.wav';
  static const String knockdown = 'sfx/knockdown.wav';
  static const String announcerRound = 'sfx/announcer_round.wav';
  static const String announcerFight = 'sfx/announcer_fight.wav';
  static const String announcerKo = 'sfx/announcer_ko.wav';
  static const String musicForsakenFoundry = 'music/forsaken_foundry.ogg';
  static const String musicHauntedCemetery = 'music/haunted_cemetery.ogg';
  static const String musicDuskPeaks = 'music/dusk_peaks.ogg';
}
