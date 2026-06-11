// Imports stage parallax layers from the downloaded packs:
// - Gothicvania Cemetery (ansimuz) -> haunted_cemetery (incl. a composed
//   foreground strip of statues/stones and the moon sky)
// - Mountain Dusk (ansimuz) -> dusk_peaks (6 layers)
//
// Run from the project root:  dart run tool/import_stage.dart
import 'dart:io';

import 'package:image/image.dart' as img;

const cemeterySrc =
    'assets_src/gothicvania_cemetery/gothicvania-cemetery-files/Assets/Environment';
const moonSrc =
    'assets_src/gothicvania_cemetery/gothicvania-cemetery-files/Assets/Phaser Demo/assets/environment/bg-moon.png';
const duskSrc = 'assets_src/mountain_dusk/MountainDuskGodot/MountainsLayers';
const cemeteryOut = 'assets/images/stages/haunted_cemetery';
const duskOut = 'assets/images/stages/dusk_peaks';

void main() {
  Directory(cemeteryOut).createSync(recursive: true);
  Directory(duskOut).createSync(recursive: true);

  copyLayer('$cemeterySrc/background.png', cemeteryOut, 'far_sky.png');
  copyLayer(moonSrc, cemeteryOut, 'moon.png');
  copyLayer('$cemeterySrc/mountains.png', cemeteryOut, 'mountains.png');
  copyLayer('$cemeterySrc/graveyard.png', cemeteryOut, 'graveyard.png');
  composeCemeteryForeground();

  for (final layer in [
    'sky', 'far-clouds', 'far-mountains', 'mountains', 'near-clouds', 'trees',
  ]) {
    copyLayer('$duskSrc/$layer.png', duskOut, '${layer.replaceAll('-', '_')}.png');
  }
  stdout.writeln('done');
}

void copyLayer(String src, String outDir, String outName) {
  final image = img.decodePng(File(src).readAsBytesSync())!;
  File('$outDir/$outName').writeAsBytesSync(img.encodePng(image));
  stdout.writeln('$outName: ${image.width}x${image.height}');
}

/// Sparse strip of darkened grave props that scrolls in front of the
/// fighters (parallax > 1) for depth.
void composeCemeteryForeground() {
  img.Image load(String name) => img.decodePng(
      File('$cemeterySrc/sliced-objects/$name.png').readAsBytesSync())!;
  final statue = load('statue');
  final stone1 = load('stone-1');
  final stone3 = load('stone-3');
  final bush = load('bush-small');

  final strip = img.Image(width: 640, height: 110, numChannels: 4);
  void place(img.Image obj, int x) {
    img.compositeImage(strip, obj, dstX: x, dstY: strip.height - obj.height);
  }

  place(statue, 30);
  place(stone1, 200);
  place(bush, 320);
  place(stone3, 470);

  // Darken to a near-silhouette so the foreground reads as depth, not noise.
  for (final p in strip) {
    if (p.a == 0) continue;
    p.r = (p.r * 0.35).round();
    p.g = (p.g * 0.3).round();
    p.b = (p.b * 0.38).round();
  }
  File('$cemeteryOut/foreground.png').writeAsBytesSync(img.encodePng(strip));
  stdout.writeln('foreground.png: ${strip.width}x${strip.height}');
}
