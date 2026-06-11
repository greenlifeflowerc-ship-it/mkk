import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../../core/constants/game_constants.dart';
import 'stage_data.dart';

/// A single stage layer drawn in world space, offset by the camera position
/// so it scrolls at [StageLayerData.parallaxFactor] of camera speed. Layers
/// either tile a PNG (crisp nearest-neighbor) or paint a procedural style.
class ParallaxStageLayer extends Component with HasGameReference<FlameGame> {
  ParallaxStageLayer({
    required this.layer,
    required this.stage,
    required this.cameraX,
  });

  final StageLayerData layer;
  final StageData stage;

  /// Live camera world-x provider (the viewfinder's position).
  final double Function() cameraX;

  Sprite? _sprite;

  static final Paint _pixelPaint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  @override
  Future<void> onLoad() async {
    final file = layer.file;
    if (file != null) {
      _sprite = Sprite(await game.images.load(file));
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    // A layer at factor f appears to move at f * camera speed.
    canvas.translate(cameraX() * (1 - layer.parallaxFactor), 0);
    if (_sprite != null) {
      _renderImage(canvas);
    } else {
      switch (layer.style) {
        case StageLayerStyle.skyGradient:
          _renderSky(canvas);
        case StageLayerStyle.structures:
          _renderStructures(canvas);
        case StageLayerStyle.floor:
          _renderFloor(canvas);
        case StageLayerStyle.foregroundFog:
          _renderFog(canvas);
      }
    }
    canvas.restore();
  }

  void _renderImage(Canvas canvas) {
    final sprite = _sprite!;
    final height = layer.worldHeight;
    final width = height * sprite.srcSize.x / sprite.srcSize.y;
    final top = layer.yBottom - height;
    if (!layer.repeatX) {
      sprite.render(canvas,
          position: Vector2(stage.leftBound, top),
          size: Vector2(width, height),
          overridePaint: _pixelPaint);
      return;
    }
    for (var x = _fullSpan.left; x < _fullSpan.right; x += width) {
      sprite.render(canvas,
          position: Vector2(x, top),
          size: Vector2(width + 2, height),
          overridePaint: _pixelPaint);
    }
  }

  Rect get _fullSpan => Rect.fromLTRB(
        stage.leftBound - 2200,
        -200,
        stage.rightBound + 2200,
        GameConstants.logicalHeight + 200,
      );

  void _renderSky(Canvas canvas) {
    final rect = _fullSpan;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: layer.colors,
        ).createShader(rect),
    );
  }

  void _renderStructures(Canvas canvas) {
    final paint = Paint()..color = layer.colors.first;
    final glow = Paint()..color = layer.colors.last;
    for (var i = -4; i < 12; i++) {
      final x = stage.leftBound + i * 460.0;
      canvas.drawRect(Rect.fromLTWH(x, 280, 190, stage.floorY - 280), paint);
      // Ember vents on each structure.
      canvas.drawRect(Rect.fromLTWH(x + 60, 460, 70, 26), glow);
    }
  }

  void _renderFloor(Canvas canvas) {
    final rect = Rect.fromLTRB(_fullSpan.left, stage.floorY, _fullSpan.right,
        GameConstants.logicalHeight + 200);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: layer.colors,
        ).createShader(rect),
    );
    // Floor seams for motion readability.
    final seam = Paint()
      ..color = layer.colors.last
      ..strokeWidth = 3;
    for (var x = _fullSpan.left; x < _fullSpan.right; x += 230) {
      canvas.drawLine(
          Offset(x, stage.floorY), Offset(x - 60, _fullSpan.bottom), seam);
    }
    canvas.drawLine(Offset(_fullSpan.left, stage.floorY),
        Offset(_fullSpan.right, stage.floorY), seam..strokeWidth = 4);
  }

  void _renderFog(Canvas canvas) {
    final rect = Rect.fromLTRB(_fullSpan.left, stage.floorY - 120,
        _fullSpan.right, GameConstants.logicalHeight + 200);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: layer.colors,
        ).createShader(rect),
    );
  }
}
