// Imports combat VFX (pimen hit sparks/smears, JasonTomLee blood) into
// standardized effect sheets, and generates original dark-metal 9-slice
// UI panels/buttons matching the IRON OMEN theme.
//
// Run from the project root:  dart run tool/import_effects.dart
import 'dart:io';

import 'package:image/image.dart' as img;

const fxDir = 'assets/images/fx';
const uiDir = 'assets/images/ui';

void main() {
  Directory(fxDir).createSync(recursive: true);
  Directory(uiDir).createSync(recursive: true);

  // Hit spark: pimen strip is already 7x 48px cells.
  final spark = img.decodePng(File(
          'assets_src/vfx_hit_spark/Hit Effect 01/Hit Effect 01 1.png')
      .readAsBytesSync())!;
  File('$fxDir/hit_spark.png').writeAsBytesSync(img.encodePng(spark));
  stdout.writeln('hit_spark: ${spark.width}x${spark.height}');

  // Block spark: same strip shifted to cyan (swap red and blue channels).
  final block = img.Image.from(spark);
  for (final p in block) {
    final r = p.r;
    p.r = p.b;
    p.b = r;
  }
  File('$fxDir/block_spark.png').writeAsBytesSync(img.encodePng(block));

  // Slash smear for sword specials: 5x 48px cells.
  final smear = img.decodePng(File(
          'assets_src/vfx_slashes/Smear VFX 01/Smear 01 Horizontal 1.png')
      .readAsBytesSync())!;
  File('$fxDir/smear.png').writeAsBytesSync(img.encodePng(smear));
  stdout.writeln('smear: ${smear.width}x${smear.height}');

  // Blood burst: 8 single 194x194 frames -> one horizontal strip.
  const cell = 194;
  final blood = img.Image(width: cell * 8, height: cell, numChannels: 4);
  for (var i = 0; i < 8; i++) {
    final frame = img.decodePng(File(
            'assets_src/vfx_blood/VFX Blood Concepts FXOnly${i + 1}.png')
        .readAsBytesSync())!;
    img.compositeImage(blood, frame, dstX: i * cell, dstY: 0);
  }
  File('$fxDir/blood_burst.png').writeAsBytesSync(img.encodePng(blood));
  stdout.writeln('blood_burst: ${blood.width}x${blood.height}');

  // Original 9-slice UI: dark steel panel and button (48x48, 16px borders).
  writeNineSlice('$uiDir/panel.png', accent: false);
  writeNineSlice('$uiDir/button.png', accent: true);
  stdout.writeln('done');
}

/// Dark beveled metal square with rivets; [accent] adds blood-red corners.
void writeNineSlice(String path, {required bool accent}) {
  const s = 48;
  final image = img.Image(width: s, height: s, numChannels: 4);
  final fill = img.ColorRgba8(20, 20, 24, 255);
  final mid = img.ColorRgba8(46, 46, 54, 255);
  final light = img.ColorRgba8(84, 84, 96, 255);
  final dark = img.ColorRgba8(8, 8, 10, 255);
  final red = img.ColorRgba8(179, 0, 27, 255);
  final ember = img.ColorRgba8(255, 106, 0, 255);

  img.fillRect(image, x1: 0, y1: 0, x2: s - 1, y2: s - 1, color: fill);
  // Outer frame.
  img.drawRect(image, x1: 0, y1: 0, x2: s - 1, y2: s - 1, color: dark);
  img.drawRect(image, x1: 1, y1: 1, x2: s - 2, y2: s - 2, color: light);
  img.drawRect(image, x1: 2, y1: 2, x2: s - 3, y2: s - 3, color: mid);
  img.drawRect(image, x1: 3, y1: 3, x2: s - 4, y2: s - 4, color: dark);
  // Corner rivets.
  for (final c in [
    [6, 6], [s - 7, 6], [6, s - 7], [s - 7, s - 7],
  ]) {
    img.fillCircle(image, x: c[0], y: c[1], radius: 2, color: light);
    image.setPixel(c[0], c[1], dark);
  }
  if (accent) {
    // Blood-red corner cuts with an ember pixel.
    for (final c in [
      [1, 1, 1], [s - 2, 1, -1], [1, s - 2, 1], [s - 2, s - 2, -1],
    ]) {
      img.drawLine(image,
          x1: c[0], y1: c[1], x2: c[0] + 5 * c[2], y2: c[1], color: red);
      image.setPixel(c[0], c[1], ember);
    }
  }
  File(path).writeAsBytesSync(img.encodePng(image));
}
