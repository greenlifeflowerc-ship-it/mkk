// Offline composite of PNG-layer stages using the same layer math as
// ParallaxStageLayer, for visual verification without a display.
// Renders the camera view at stage center into 960x540 PNGs.
//
// Run from the project root:  dart run tool/preview_stage.dart
import 'dart:io';

import 'package:image/image.dart' as img;

const double camX = 1400, camY = 540;
const double viewW = 1920, viewH = 1080;
const double outScale = 0.5;

class Layer {
  Layer(this.file, this.parallax, this.worldHeight, this.yBottom);
  final String file;
  final double parallax;
  final double worldHeight;
  final double yBottom;
}

final stages = <String, List<Layer>>{
  'haunted_cemetery': [
    Layer('assets/images/stages/haunted_cemetery/moon.png', 0.08, 1150, 1040),
    Layer('assets/images/stages/haunted_cemetery/mountains.png', 0.35, 950, 935),
    Layer('assets/images/stages/haunted_cemetery/graveyard.png', 0.8, 540, 940),
    Layer('FLOOR', 1.0, 0, 0),
    Layer('assets/images/stages/haunted_cemetery/foreground.png', 1.15, 300, 1120),
  ],
  'dusk_peaks': [
    Layer('assets/images/stages/dusk_peaks/sky.png', 0.05, 1450, 1050),
    Layer('assets/images/stages/dusk_peaks/far_clouds.png', 0.15, 1250, 1020),
    Layer('assets/images/stages/dusk_peaks/far_mountains.png', 0.3, 1150, 1000),
    Layer('assets/images/stages/dusk_peaks/mountains.png', 0.55, 1050, 980),
    Layer('assets/images/stages/dusk_peaks/near_clouds.png', 0.72, 950, 965),
    Layer('assets/images/stages/dusk_peaks/trees.png', 0.92, 760, 950),
    Layer('FLOOR', 1.0, 0, 0),
  ],
};

void main() {
  stages.forEach(renderStage);
}

void renderStage(String name, List<Layer> layers) {
  final out = img.Image(
      width: (viewW * outScale).round(), height: (viewH * outScale).round());
  img.fill(out, color: img.ColorRgb8(10, 10, 12));

  for (final layer in layers) {
    if (layer.file == 'FLOOR') {
      final floorY = ((920 - (camY - viewH / 2)) * outScale).round();
      img.fillRect(out,
          x1: 0, y1: floorY, x2: out.width - 1, y2: out.height - 1,
          color: img.ColorRgb8(26, 28, 30));
      // Fighter silhouettes (400 px) at spawn positions.
      for (final fx in [900.0, 1900.0]) {
        final vx = ((fx - (camX - viewW / 2)) * outScale).round();
        img.fillRect(out,
            x1: vx - 28, y1: floorY - (400 * outScale).round(), x2: vx + 28,
            y2: floorY, color: img.ColorRgba8(200, 60, 60, 170));
      }
      continue;
    }
    final src = img.decodePng(File(layer.file).readAsBytesSync())!;
    final h = layer.worldHeight;
    final w = h * src.width / src.height;
    final top = layer.yBottom - h;
    final offset = camX * (1 - layer.parallax);
    for (var x = -2200.0; x < 5200; x += w) {
      final viewX = x + offset - (camX - viewW / 2);
      final viewY = top - (camY - viewH / 2);
      final dst = img.copyResize(src,
          width: (w * outScale).round(),
          height: (h * outScale).round(),
          interpolation: img.Interpolation.nearest);
      img.compositeImage(out, dst,
          dstX: (viewX * outScale).round(), dstY: (viewY * outScale).round());
    }
  }
  final path = '${Directory.systemTemp.path}/preview_$name.png';
  File(path).writeAsBytesSync(img.encodePng(out));
  stdout.writeln('wrote $path');
}

