import 'dart:ui';

import '../../core/constants/audio_keys.dart';
import '../../core/constants/game_constants.dart';
import '../../game/stage/stage_data.dart';

/// Stage #2: Haunted Cemetery — a moonless graveyard under dead mountains.
/// Art: "Gothicvania Cemetery" by ansimuz (free for commercial use),
/// imported by tool/import_stage.dart; floor and fog stay procedural.
StageData hauntedCemetery() {
  return const StageData(
    id: 'haunted_cemetery',
    displayName: 'HAUNTED CEMETERY',
    floorY: GameConstants.floorY,
    leftBound: GameConstants.stageLeftBound,
    rightBound: GameConstants.stageRightBound,
    musicKey: AudioKeys.musicHauntedCemetery,
    layers: [
      // Glowing-moon sky from the cemetery pack's demo scene.
      StageLayerData(
        file: 'stages/haunted_cemetery/moon.png',
        parallaxFactor: 0.08,
        worldHeight: 1150,
        yBottom: 1040,
      ),
      StageLayerData(
        file: 'stages/haunted_cemetery/mountains.png',
        parallaxFactor: 0.35,
        worldHeight: 950,
        yBottom: 935,
      ),
      StageLayerData(
        file: 'stages/haunted_cemetery/graveyard.png',
        parallaxFactor: 0.8,
        worldHeight: 540,
        yBottom: 940,
      ),
      StageLayerData(
        parallaxFactor: 1.0,
        style: StageLayerStyle.floor,
        colors: [Color(0xFF2E3330), Color(0xFF15181B), Color(0xFF0B0D10)],
      ),
      // Silhouetted grave props scrolling in front of the fighters.
      StageLayerData(
        file: 'stages/haunted_cemetery/foreground.png',
        parallaxFactor: 1.15,
        worldHeight: 300,
        yBottom: 1120,
      ),
      StageLayerData(
        parallaxFactor: 1.2,
        style: StageLayerStyle.foregroundFog,
        colors: [Color(0x00000000), Color(0x70101A18)],
      ),
    ],
  );
}
