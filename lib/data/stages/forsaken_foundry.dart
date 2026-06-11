import 'dart:ui';

import '../../core/constants/audio_keys.dart';
import '../../core/constants/game_constants.dart';
import '../../game/stage/stage_data.dart';

/// Stage #1: The Forsaken Foundry — a dead steelworks lit by dying embers.
/// Procedural placeholder palette until Phase 3 art lands.
StageData forsakenFoundry() {
  return const StageData(
    id: 'forsaken_foundry',
    displayName: 'FORSAKEN FOUNDRY',
    floorY: GameConstants.floorY,
    leftBound: GameConstants.stageLeftBound,
    rightBound: GameConstants.stageRightBound,
    musicKey: AudioKeys.musicForsakenFoundry,
    layers: [
      StageLayerData(
        parallaxFactor: 0.15,
        style: StageLayerStyle.skyGradient,
        colors: [Color(0xFF0A0A0C), Color(0xFF26060B), Color(0xFF3D0A10)],
      ),
      StageLayerData(
        parallaxFactor: 0.45,
        style: StageLayerStyle.structures,
        colors: [Color(0xFF141417), Color(0xFFB3001B)],
      ),
      StageLayerData(
        parallaxFactor: 1.0,
        style: StageLayerStyle.floor,
        colors: [Color(0xFF3A3A40), Color(0xFF1A1A1E), Color(0xFF0E0E10)],
      ),
      StageLayerData(
        parallaxFactor: 1.15,
        style: StageLayerStyle.foregroundFog,
        colors: [Color(0x00000000), Color(0x66160407)],
      ),
    ],
  );
}
