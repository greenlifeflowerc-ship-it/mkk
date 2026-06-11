// Converts CC0 fighter packs (LuizMelo, in assets_src/) into the IRON OMEN
// 17-animation sheet contract, plus a select-screen portrait and a projectile
// sprite sheet per fighter.
//
// Derived animations: walk_backward = run reversed, get_up = death reversed,
// crouch = idle squashed to the feet line, block = brace frame + drawn guard
// arc, attack sheets recombined from the packs' Attack strips.
//
// Run from the project root:  dart run tool/import_martial_hero.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

class SourcePack {
  const SourcePack({
    required this.fighterId,
    required this.srcDir,
    required this.cell,
    required this.flip,
    required this.idleFile,
    required this.runFile,
    required this.jumpFiles,
    required this.attackFiles,
    required this.takeHitFile,
    required this.deathFile,
    required this.projectileColor,
  });

  final String fighterId;
  final String srcDir;

  /// Square cell size of this pack's strips.
  final int cell;

  /// True when the source art faces left (our convention is right).
  final bool flip;

  final String idleFile;
  final String runFile;
  final List<String> jumpFiles;
  final List<String> attackFiles;
  final String takeHitFile;
  final String deathFile;

  /// RGB for the generated special-move projectile.
  final List<int> projectileColor;
}

const packs = [
  SourcePack(
    fighterId: 'ash_viper',
    srcDir: 'assets_src/martial_hero_1',
    cell: 200,
    flip: false,
    idleFile: 'Idle.png',
    runFile: 'Run.png',
    jumpFiles: ['Jump.png', 'Fall.png'],
    attackFiles: ['Attack1.png', 'Attack2.png'],
    takeHitFile: 'Take Hit.png',
    deathFile: 'Death.png',
    projectileColor: [255, 170, 40],
  ),
  SourcePack(
    fighterId: 'iron_ghost',
    srcDir: 'assets_src/martial_hero_2',
    cell: 200,
    flip: true,
    idleFile: 'Idle.png',
    runFile: 'Run.png',
    jumpFiles: ['Jump.png', 'Fall.png'],
    attackFiles: ['Attack1.png', 'Attack2.png'],
    takeHitFile: 'Take hit.png',
    deathFile: 'Death.png',
    projectileColor: [255, 60, 60],
  ),
  SourcePack(
    fighterId: 'night_blade',
    srcDir: 'assets_src/martial_hero_3/Martial Hero 3/Sprite',
    cell: 126,
    flip: false,
    idleFile: 'Idle.png',
    runFile: 'Run.png',
    jumpFiles: ['Going Up.png', 'Going Down.png'],
    attackFiles: ['Attack1.png', 'Attack2.png', 'Attack3.png'],
    takeHitFile: 'Take Hit.png',
    deathFile: 'Death.png',
    projectileColor: [180, 90, 255],
  ),
  SourcePack(
    fighterId: 'grave_warden',
    srcDir: 'assets_src/fantasy_warrior/Fantasy Warrior/Sprites',
    cell: 162,
    flip: false,
    idleFile: 'Idle.png',
    runFile: 'Run.png',
    jumpFiles: ['Jump.png', 'Fall.png'],
    attackFiles: ['Attack1.png', 'Attack2.png', 'Attack3.png'],
    takeHitFile: 'Take hit.png',
    deathFile: 'Death.png',
    projectileColor: [90, 230, 130],
  ),
];

void main() {
  for (final pack in packs) {
    processPack(pack);
  }
  stdout.writeln('done');
}

void processPack(SourcePack pack) {
  final cell = pack.cell;
  final idle = loadFrames(pack, pack.idleFile);
  final run = loadFrames(pack, pack.runFile);
  final jumpArc = [
    for (final f in pack.jumpFiles) ...loadFrames(pack, f),
  ];
  final attacks = [for (final f in pack.attackFiles) loadFrames(pack, f)];
  final takeHit = loadFrames(pack, pack.takeHitFile);
  final death = loadFrames(pack, pack.deathFile);

  final first = attacks.first;
  final second = attacks.length > 1 ? attacks[1] : attacks.first;
  final last = attacks.last;

  final bounds = measure(idle.first, cell);

  final braceFrame = takeHit.first;
  final blockHigh = [
    for (var i = 0; i < 4; i++)
      withGuardArc(braceFrame, bounds, cell, pulse: i, low: false),
  ];
  final blockLow = [
    for (var i = 0; i < 4; i++)
      withGuardArc(squashToFeet(braceFrame, bounds, cell, 0.74), bounds, cell,
          pulse: i, low: true),
  ];
  final crouch = [
    for (final f in resample(idle, 4)) squashToFeet(f, bounds, cell, 0.74),
  ];

  final sheets = <String, List<img.Image>>{
    'idle': resample(idle, 8),
    'walk_forward': resample(run, 8),
    'walk_backward': resample(run.reversed.toList(), 8),
    'crouch': crouch,
    'jump_up': resample(jumpArc, 6),
    'jump_forward': resample(jumpArc, 6),
    'punch_combo': [...resample(first, 4), ...resample(second, 4)],
    'kick_combo': resample(last, 8),
    'special_attack': [...resample(first, 6), ...resample(last, 6)],
    'block_high': blockHigh,
    'block_low': blockLow,
    'hit': resample(takeHit, 4),
    'knockdown': resample(death, 8),
    'get_up': resample(death.reversed.toList(), 6),
    'victory': resample(idle, 6),
    'defeat': List.filled(6, death.last),
    'finisher': [...resample(last, 6), ...resample(first, 6)],
  };

  final outDir = 'assets/images/fighters/${pack.fighterId}';
  Directory(outDir).createSync(recursive: true);
  sheets.forEach((name, frames) {
    final sheet =
        img.Image(width: cell * frames.length, height: cell, numChannels: 4);
    for (var i = 0; i < frames.length; i++) {
      img.compositeImage(sheet, frames[i], dstX: i * cell, dstY: 0);
    }
    File('$outDir/$name.png').writeAsBytesSync(img.encodePng(sheet));
  });

  writePortrait(pack, idle.first, bounds, outDir);
  writeProjectile(pack, outDir);

  stdout.writeln('${pack.fighterId}: cell=$cell feetY=${bounds.feetY} '
      'bodyHeight=${bounds.height} bodyHalfWidth=${bounds.halfWidth} '
      '(renderScale ~${(400 / bounds.height).toStringAsFixed(2)})');
}

/// Square head-and-shoulders crop from the idle pose, upscaled 4x nearest.
void writePortrait(
    SourcePack pack, img.Image idleFrame, BodyBounds bounds, String outDir) {
  final size = math.max(24, (bounds.height * 0.62).round());
  final cx = bounds.centerX;
  final cy = bounds.topY + (size * 0.45).round();
  final x = (cx - size ~/ 2).clamp(0, idleFrame.width - size);
  final y = (cy - size ~/ 2).clamp(0, idleFrame.height - size);
  var crop = img.copyCrop(idleFrame, x: x, y: y, width: size, height: size);
  crop = img.copyResize(crop,
      width: size * 4, height: size * 4,
      interpolation: img.Interpolation.nearest);
  File('$outDir/portrait.png').writeAsBytesSync(img.encodePng(crop));
}

/// 4-frame 64x64 glowing-orb projectile sheet tinted per fighter.
void writeProjectile(SourcePack pack, String outDir) {
  const c = 64;
  final sheet = img.Image(width: c * 4, height: c, numChannels: 4);
  final r = pack.projectileColor[0];
  final g = pack.projectileColor[1];
  final b = pack.projectileColor[2];
  for (var f = 0; f < 4; f++) {
    final cx = f * c + c ~/ 2 + 6;
    final cy = c ~/ 2;
    final radius = 13 + (f % 2) * 2;
    // Trail streaks behind the orb.
    for (var t = 0; t < 3; t++) {
      img.fillRect(sheet,
          x1: f * c + 2, y1: cy - 6 + t * 5,
          x2: cx - radius + 4, y2: cy - 4 + t * 5,
          color: img.ColorRgba8(r, g, b, 90 - t * 20));
    }
    img.fillCircle(sheet,
        x: cx, y: cy, radius: radius + 5,
        color: img.ColorRgba8(r, g, b, 70));
    img.fillCircle(sheet,
        x: cx, y: cy, radius: radius, color: img.ColorRgba8(r, g, b, 220));
    img.fillCircle(sheet,
        x: cx, y: cy, radius: radius - 6,
        color: img.ColorRgba8(255, 255, 240, 255));
  }
  File('$outDir/projectile.png').writeAsBytesSync(img.encodePng(sheet));
}

List<img.Image> loadFrames(SourcePack pack, String file) {
  final sheet =
      img.decodePng(File('${pack.srcDir}/$file').readAsBytesSync())!;
  final count = sheet.width ~/ pack.cell;
  return [
    for (var i = 0; i < count; i++)
      () {
        var frame = img.copyCrop(sheet,
            x: i * pack.cell, y: 0, width: pack.cell, height: pack.cell);
        if (pack.flip) frame = img.flipHorizontal(frame);
        return frame;
      }(),
  ];
}

/// Picks [n] frames spread evenly across [frames] (duplicating or skipping).
List<img.Image> resample(List<img.Image> frames, int n) {
  return [
    for (var i = 0; i < n; i++) frames[(i * frames.length) ~/ n],
  ];
}

class BodyBounds {
  BodyBounds(this.feetY, this.topY, this.centerX, this.halfWidth);

  final int feetY;
  final int topY;
  final int centerX;
  final int halfWidth;

  int get height => feetY - topY;
}

/// Alpha bounding box of the character in a frame.
BodyBounds measure(img.Image frame, int cell) {
  var minX = frame.width, maxX = 0, minY = frame.height, maxY = 0;
  for (var y = 0; y < frame.height; y++) {
    for (var x = 0; x < frame.width; x++) {
      if (frame.getPixel(x, y).a > 24) {
        minX = math.min(minX, x);
        maxX = math.max(maxX, x);
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
      }
    }
  }
  return BodyBounds(
      maxY, minY, (minX + maxX) ~/ 2, math.max(1, (maxX - minX) ~/ 2));
}

/// Vertically squashes a frame towards its feet line (for crouch poses).
img.Image squashToFeet(
    img.Image frame, BodyBounds bounds, int cell, double factor) {
  final squashed = img.copyResize(
    frame,
    width: cell,
    height: (cell * factor).round(),
    interpolation: img.Interpolation.nearest,
  );
  final out = img.Image(width: cell, height: cell, numChannels: 4);
  final offsetY = bounds.feetY - (bounds.feetY * factor).round();
  img.compositeImage(out, squashed, dstX: 0, dstY: offsetY);
  return out;
}

/// Draws a translucent energy arc in front of the fighter so block stances
/// read instantly (the source packs have no guard animation).
img.Image withGuardArc(img.Image frame, BodyBounds bounds, int cell,
    {required int pulse, required bool low}) {
  final out = img.Image.from(frame);
  final cy = low
      ? bounds.feetY - (bounds.height * 0.3).round()
      : bounds.feetY - (bounds.height * 0.55).round();
  final cx = bounds.centerX + bounds.halfWidth - 2;
  final radius = low ? (bounds.height * 0.42) : (bounds.height * 0.62);
  final alpha = 120 + 28 * (pulse % 2);
  final glow = img.ColorRgba8(140, 210, 255, alpha);
  final rim = img.ColorRgba8(220, 245, 255, alpha + 40);

  final top = (cy - radius).round();
  final bottom = (cy + radius).round();
  for (var y = top; y <= bottom; y++) {
    if (y < 0 || y >= out.height) continue;
    final dy = (y - cy).toDouble();
    final dx = math.sqrt(math.max(0, radius * radius - dy * dy));
    final x = (cx + dx * 0.45).round();
    for (var t = 0; t < 3; t++) {
      final px = x + t;
      if (px < 0 || px >= out.width) continue;
      out.setPixel(px, y, t == 1 ? rim : glow);
    }
  }
  return out;
}
