import 'package:flame/components.dart';

import 'parallax_layer.dart';
import 'stage_data.dart';

/// Builds a stage from [StageData]: one [ParallaxStageLayer] per layer,
/// back to front.
class StageComponent extends Component {
  StageComponent({required this.stage, required this.cameraX});

  final StageData stage;
  final double Function() cameraX;

  @override
  Future<void> onLoad() async {
    for (final layer in stage.layers) {
      await add(ParallaxStageLayer(
        layer: layer,
        stage: stage,
        cameraX: cameraX,
      ));
    }
  }
}
