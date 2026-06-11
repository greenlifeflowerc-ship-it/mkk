import 'dart:ui';

/// How a procedural layer is painted when no PNG art is assigned.
enum StageLayerStyle { skyGradient, structures, floor, foregroundFog }

/// One parallax layer of a stage: either a PNG image (tiled horizontally
/// and scaled with crisp pixels) or a procedural placeholder style.
class StageLayerData {
  const StageLayerData({
    this.file,
    required this.parallaxFactor,
    this.style = StageLayerStyle.skyGradient,
    this.colors = const [Color(0xFF000000)],
    this.worldHeight = 1080,
    this.yBottom = 1080,
    this.repeatX = true,
  });

  /// Image path under assets/images/ (e.g. `stages/<id>/far.png`);
  /// null = paint procedurally using [style] and [colors].
  final String? file;

  /// 0 = pinned to camera (infinitely far), 1 = moves with the world,
  /// > 1 = foreground (moves faster than the fight plane).
  final double parallaxFactor;

  final StageLayerStyle style;

  /// Palette for procedural painting, background to foreground.
  final List<Color> colors;

  /// Image layers: rendered height in world px (width keeps aspect) and the
  /// world y where the layer's bottom edge sits.
  final double worldHeight;
  final double yBottom;

  /// Tile the image horizontally across the stage span.
  final bool repeatX;
}

/// Complete data-driven definition of a stage.
class StageData {
  const StageData({
    required this.id,
    required this.displayName,
    required this.floorY,
    required this.leftBound,
    required this.rightBound,
    required this.musicKey,
    required this.layers,
  });

  final String id;
  final String displayName;
  final double floorY;
  final double leftBound;
  final double rightBound;
  final String musicKey;

  /// Back-to-front draw order.
  final List<StageLayerData> layers;

  double get width => rightBound - leftBound;
}
