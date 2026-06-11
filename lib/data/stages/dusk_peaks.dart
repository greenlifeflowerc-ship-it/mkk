import 'dart:ui';

import '../../core/constants/audio_keys.dart';
import '../../core/constants/game_constants.dart';
import '../../game/stage/stage_data.dart';

/// Stage #3: Dusk Peaks — a dying-light mountain pass, six parallax bands
/// deep. Art: "Mountain Dusk" by ansimuz (free for commercial use),
/// imported by tool/import_stage.dart.
StageData duskPeaks() {
  return const StageData(
    id: 'dusk_peaks',
    displayName: 'DUSK PEAKS',
    floorY: GameConstants.floorY,
    leftBound: GameConstants.stageLeftBound,
    rightBound: GameConstants.stageRightBound,
    musicKey: AudioKeys.musicDuskPeaks,
    layers: [
      StageLayerData(
        file: 'stages/dusk_peaks/sky.png',
        parallaxFactor: 0.05,
        worldHeight: 1450,
        yBottom: 1050,
      ),
      StageLayerData(
        file: 'stages/dusk_peaks/far_clouds.png',
        parallaxFactor: 0.15,
        worldHeight: 1250,
        yBottom: 1020,
      ),
      StageLayerData(
        file: 'stages/dusk_peaks/far_mountains.png',
        parallaxFactor: 0.3,
        worldHeight: 1150,
        yBottom: 1000,
      ),
      StageLayerData(
        file: 'stages/dusk_peaks/mountains.png',
        parallaxFactor: 0.55,
        worldHeight: 1050,
        yBottom: 980,
      ),
      StageLayerData(
        file: 'stages/dusk_peaks/near_clouds.png',
        parallaxFactor: 0.72,
        worldHeight: 950,
        yBottom: 965,
      ),
      StageLayerData(
        file: 'stages/dusk_peaks/trees.png',
        parallaxFactor: 0.92,
        worldHeight: 760,
        yBottom: 950,
      ),
      StageLayerData(
        parallaxFactor: 1.0,
        style: StageLayerStyle.floor,
        colors: [Color(0xFF3B2E36), Color(0xFF1D161C), Color(0xFF0E0A0E)],
      ),
      StageLayerData(
        parallaxFactor: 1.15,
        style: StageLayerStyle.foregroundFog,
        colors: [Color(0x00000000), Color(0x661A0E14)],
      ),
    ],
  );
}
