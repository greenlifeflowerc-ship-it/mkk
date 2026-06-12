// Converts the AI-generated Void Drake grid sheets (assets_src/void_drake/raw)
// into the IRON OMEN 17-animation contract: green-screen keyed, sliced from
// their generation grids, scaled to a shared body height and re-aligned on a
// common feet baseline, then packed as horizontal strips.
//
// Run from the project root:  dart run tool/import_void_drake.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const rawDir = 'assets_src/void_drake/raw';
const outDir = 'assets/images/fighters/void_drake';

/// Output cell + alignment targets (source pixels of the packed sheets).
const cell = 320;
const baselineY = 290;
const targetBodyHeight = 230;

/// How a sheet's frames sit vertically.
/// pin: every frame's lowest pixel sits on the baseline (grounded poses).
/// preserve: keep each frame's height above the sheet's ground line so
/// airborne arcs baked into the art survive (jumps, knockdown).
enum Align { pin, preserve }

class SheetSpec {
  const SheetSpec(this.key, this.cols, this.rows, this.frames, this.align,
      {this.scaleOverride, this.frameMap, this.autoGrid = false});

  final String key;
  final int cols;
  final int rows;
  final int frames;
  final Align align;

  /// Manual scale fix when the max-bbox heuristic misreads a sheet (e.g. the
  /// finisher dragon inflating the bounding box).
  final double? scaleOverride;

  /// Output-frame -> grid-cell remap, for skipping bad generated cells.
  final List<int>? frameMap;

  /// Detect row/column bands from pixel density instead of slicing the
  /// canvas into equal cells — for sheets whose drawn grid drifted.
  final bool autoGrid;
}

const sheets = [
  SheetSpec('idle', 4, 2, 8, Align.pin),
  SheetSpec('walk_forward', 4, 2, 8, Align.pin),
  SheetSpec('walk_backward', 4, 2, 8, Align.pin),
  SheetSpec('crouch', 2, 2, 4, Align.pin),
  SheetSpec('jump_up', 3, 2, 6, Align.preserve),
  SheetSpec('jump_forward', 3, 2, 6, Align.preserve),
  SheetSpec('punch_combo', 4, 2, 8, Align.pin),
  SheetSpec('kick_combo', 4, 2, 8, Align.pin),
  SheetSpec('special_attack', 4, 3, 12, Align.pin),
  SheetSpec('block_high', 2, 2, 4, Align.pin),
  SheetSpec('block_low', 2, 2, 4, Align.pin),
  SheetSpec('hit', 2, 2, 4, Align.pin),
  SheetSpec('knockdown', 4, 2, 8, Align.preserve),
  SheetSpec('get_up', 3, 2, 6, Align.pin),
  SheetSpec('victory', 3, 2, 6, Align.pin),
  SheetSpec('defeat', 3, 2, 6, Align.pin),
  SheetSpec('finisher', 4, 3, 12, Align.pin, autoGrid: true),
];

void main() {
  Directory(outDir).createSync(recursive: true);
  for (final spec in sheets) {
    processSheet(spec);
  }
  processPortrait();
  processProjectile();
  stdout.writeln('done: cell=$cell feetY=$baselineY '
      'renderScale ~${(400 / targetBodyHeight).toStringAsFixed(2)}');
}

void processSheet(SheetSpec spec) {
  final source = img.decodePng(
      File('$rawDir/${spec.key}.png').readAsBytesSync())!;
  final cellW = source.width ~/ spec.cols;
  final cellH = source.height ~/ spec.rows;

  final cells = spec.autoGrid
      ? detectCells(source, spec)
      : [
          for (var i = 0; i < spec.frames; i++)
            () {
              final src = spec.frameMap == null ? i : spec.frameMap![i];
              return Box(
                (src % spec.cols) * cellW,
                (src ~/ spec.cols) * cellH,
                (src % spec.cols) * cellW + cellW - 1,
                (src ~/ spec.cols) * cellH + cellH - 1,
              );
            }(),
        ];

  final raw = <img.Image>[];
  for (final c in cells) {
    // The generations are RGB; alpha must exist before keying can clear it.
    final frame = img.copyCrop(source,
            x: c.minX, y: c.minY, width: c.width, height: c.height)
        .convert(numChannels: 4);
    keyOutGreen(frame);
    raw.add(frame);
  }

  final boxes = [for (final f in raw) bbox(f)];
  final maxHeight =
      boxes.where((b) => b != null).map((b) => b!.height).fold(1, math.max);
  final scale = spec.scaleOverride ?? targetBodyHeight / maxHeight;
  // The sheet's ground line: the lowest body pixel of any frame (the
  // grounded ones); airborne frames keep their distance above it.
  final groundY =
      boxes.where((b) => b != null).map((b) => b!.maxY).fold(0, math.max);

  final out =
      img.Image(width: cell * spec.frames, height: cell, numChannels: 4);
  for (var i = 0; i < spec.frames; i++) {
    final box = boxes[i];
    if (box == null) continue;
    final scaled = img.copyResize(
      raw[i],
      width: (raw[i].width * scale).round(),
      height: (raw[i].height * scale).round(),
      interpolation: img.Interpolation.nearest,
    );
    final sBox = Box(
      (box.minX * scale).round(),
      (box.minY * scale).round(),
      (box.maxX * scale).round(),
      (box.maxY * scale).round(),
    );

    final lift = spec.align == Align.preserve
        ? ((groundY - box.maxY) * scale).round()
        : 0;
    final dstY = baselineY - lift - sBox.maxY;
    final anchorX = box.height >= box.width
        ? (feetCenterX(raw[i], box) * scale).round()
        : (sBox.minX + sBox.maxX) ~/ 2;
    final dstX = cell ~/ 2 - anchorX;

    img.compositeImage(out, scaled,
        dstX: i * cell + dstX.clamp(-sBox.minX, cell - 1 - sBox.maxX),
        dstY: dstY.clamp(-sBox.minY, cell - 1 - sBox.maxY));
  }
  File('$outDir/${spec.key}.png').writeAsBytesSync(img.encodePng(out));

  final standH = (maxHeight * scale).round();
  stdout.writeln('${spec.key}: cells ${cellW}x$cellH scale '
      '${scale.toStringAsFixed(3)} bodyH=$standH frames=${spec.frames}');
}

void processPortrait() {
  final source =
      img.decodePng(File('$rawDir/portrait.png').readAsBytesSync())!;
  final resized = img.copyResize(source,
      width: 256, height: 256, interpolation: img.Interpolation.average);
  File('$outDir/portrait.png').writeAsBytesSync(img.encodePng(resized));
  stdout.writeln('portrait: 256x256');
}

/// Projectile contract is strict: 4 frames of 64px cells (256x64),
/// dragon head flying right.
void processProjectile() {
  final source =
      img.decodePng(File('$rawDir/projectile.png').readAsBytesSync())!;
  final cellW = source.width ~/ 2;
  final cellH = source.height ~/ 2;
  final out = img.Image(width: 256, height: 64, numChannels: 4);
  for (var i = 0; i < 4; i++) {
    var frame = img.copyCrop(source,
            x: (i % 2) * cellW, y: (i ~/ 2) * cellH,
            width: cellW, height: cellH)
        .convert(numChannels: 4);
    // The generated grid drew frames 1 and 3 facing left; our convention
    // is right.
    if (i == 0 || i == 2) frame = img.flipHorizontal(frame);
    keyOutGreen(frame);
    final box = bbox(frame);
    if (box == null) continue;
    var crop = img.copyCrop(frame,
        x: box.minX, y: box.minY, width: box.width, height: box.height);
    final scale = math.min(58 / crop.width, 50 / crop.height);
    crop = img.copyResize(crop,
        width: math.max(1, (crop.width * scale).round()),
        height: math.max(1, (crop.height * scale).round()),
        interpolation: img.Interpolation.nearest);
    img.compositeImage(out, crop,
        dstX: i * 64 + (64 - crop.width) ~/ 2,
        dstY: (64 - crop.height) ~/ 2);
  }
  File('$outDir/projectile.png').writeAsBytesSync(img.encodePng(out));
  stdout.writeln('projectile: 256x64');
}

/// Locates the sheet's real cells from pixel density: finds [spec.rows]
/// horizontal content bands separated by green gaps, then [spec.cols]
/// column clusters inside each band. Survives grids the model drew with
/// uneven row heights.
List<Box> detectCells(img.Image source, SheetSpec spec) {
  bool isContent(int x, int y) {
    final p = source.getPixel(x, y);
    final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
    return !(g > 90 && g > math.max(r, b) * 1.45);
  }

  // Sample every 4th pixel for speed; densities only need to be relative.
  final rowDensity = List<int>.filled(source.height, 0);
  for (var y = 0; y < source.height; y += 2) {
    for (var x = 0; x < source.width; x += 4) {
      if (isContent(x, y)) rowDensity[y]++;
    }
  }
  final rowBands = _bands(rowDensity, source.width ~/ 400, 40, spec.rows);

  final cells = <Box>[];
  for (final band in rowBands) {
    final colDensity = List<int>.filled(source.width, 0);
    for (var x = 0; x < source.width; x++) {
      for (var y = band.$1; y <= band.$2; y += 2) {
        if (isContent(x, y)) colDensity[x]++;
      }
    }
    var cols = _bands(colDensity, 2, 40, spec.cols);
    if (cols.length < spec.cols) {
      // Fallback: equal slices of the band.
      final w = source.width ~/ spec.cols;
      cols = [
        for (var c = 0; c < spec.cols; c++) (c * w, c * w + w - 1),
      ];
    }
    for (final col in cols) {
      cells.add(Box(
        math.max(0, col.$1 - 10),
        math.max(0, band.$1 - 10),
        math.min(source.width - 1, col.$2 + 10),
        math.min(source.height - 1, band.$2 + 10),
      ));
    }
  }
  if (cells.length != spec.frames) {
    throw StateError('${spec.key}: autoGrid found ${cells.length} cells, '
        'expected ${spec.frames}');
  }
  return cells;
}

/// Maximal runs where density > [threshold], merging runs separated by gaps
/// smaller than [mergeGap]; returns the [count] widest runs in order.
List<(int, int)> _bands(
    List<int> density, int threshold, int mergeGap, int count) {
  final runs = <(int, int)>[];
  int? start;
  for (var i = 0; i <= density.length; i++) {
    final on = i < density.length && density[i] > threshold;
    if (on) {
      start ??= i;
    } else if (start != null) {
      runs.add((start, i - 1));
      start = null;
    }
  }
  // Merge near-adjacent runs (detached embers, scarf tips).
  final merged = <(int, int)>[];
  for (final run in runs) {
    if (merged.isNotEmpty && run.$1 - merged.last.$2 <= mergeGap) {
      merged[merged.length - 1] = (merged.last.$1, run.$2);
    } else {
      merged.add(run);
    }
  }
  merged.sort((a, b) => (b.$2 - b.$1).compareTo(a.$2 - a.$1));
  final top = merged.take(count).toList()
    ..sort((a, b) => a.$1.compareTo(b.$1));
  return top;
}

/// Keys out the #00FF00 chroma background in place and despills the green
/// channel on kept pixels so purple glows keep clean edges.
void keyOutGreen(img.Image frame) {
  for (final p in frame) {
    final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
    final maxRb = math.max(r, b);
    if (g > 90 && g > maxRb * 1.45) {
      p.setRgba(0, 0, 0, 0);
    } else if (g > maxRb) {
      p.g = maxRb;
    }
  }
}

class Box {
  Box(this.minX, this.minY, this.maxX, this.maxY);

  final int minX;
  final int minY;
  final int maxX;
  final int maxY;

  int get width => maxX - minX + 1;
  int get height => maxY - minY + 1;
}

/// Alpha bounding box, or null for an empty frame.
Box? bbox(img.Image frame) {
  var minX = frame.width, maxX = -1, minY = frame.height, maxY = -1;
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
  return maxX < 0 ? null : Box(minX, minY, maxX, maxY);
}

/// Horizontal center of the feet cluster (alpha in the bottom 14% of the
/// body) so extended limbs don't drag the body pivot around.
double feetCenterX(img.Image frame, Box box) {
  final int cut = box.maxY - math.max(4, (box.height * 0.14).round());
  var sum = 0.0;
  var count = 0;
  for (int y = cut; y <= box.maxY; y++) {
    for (int x = box.minX; x <= box.maxX; x++) {
      if (frame.getPixel(x, y).a > 24) {
        sum += x;
        count++;
      }
    }
  }
  return count == 0 ? (box.minX + box.maxX) / 2 : sum / count;
}
