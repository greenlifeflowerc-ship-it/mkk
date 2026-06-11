// Generates placeholder sprite sheets for every fighter animation so all
// systems are testable before real art exists.
//
// Output: assets/images/fighters/ash_viper/<animation>.png — one horizontal
// strip of 512x512 cells per animation, capsule fighter with limb blocks,
// distinct tint per animation, feet on the y=500 row, facing +x (right).
//
// Run from the project root:  dart run tool/generate_placeholders.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const int cell = 512;
const int feetY = 500;
const String outputDir = 'assets/images/fighters/ash_viper';

class AnimSpec {
  const AnimSpec(this.key, this.frames, this.r, this.g, this.b);

  final String key;
  final int frames;
  final int r;
  final int g;
  final int b;
}

const List<AnimSpec> specs = [
  AnimSpec('idle', 8, 120, 150, 130),
  AnimSpec('walk_forward', 8, 80, 170, 90),
  AnimSpec('walk_backward', 8, 70, 150, 150),
  AnimSpec('crouch', 4, 140, 140, 70),
  AnimSpec('jump_up', 6, 90, 140, 200),
  AnimSpec('jump_forward', 6, 70, 110, 220),
  AnimSpec('punch_combo', 8, 200, 60, 60),
  AnimSpec('kick_combo', 8, 220, 120, 40),
  AnimSpec('special_attack', 12, 160, 70, 200),
  AnimSpec('block_high', 4, 110, 120, 140),
  AnimSpec('block_low', 4, 80, 90, 110),
  AnimSpec('hit', 4, 220, 200, 60),
  AnimSpec('knockdown', 8, 200, 70, 160),
  AnimSpec('get_up', 6, 230, 140, 180),
  AnimSpec('victory', 6, 230, 190, 60),
  AnimSpec('defeat', 6, 130, 40, 50),
  AnimSpec('finisher', 12, 255, 30, 30),
];

void main() {
  Directory(outputDir).createSync(recursive: true);
  for (final spec in specs) {
    final sheet = img.Image(
        width: cell * spec.frames, height: cell, numChannels: 4);
    for (var f = 0; f < spec.frames; f++) {
      drawFrame(sheet, spec, f, f * cell);
    }
    final file = File('$outputDir/${spec.key}.png');
    file.writeAsBytesSync(img.encodePng(sheet));
    stdout.writeln('wrote ${file.path} (${spec.frames} frames)');
  }
  stdout.writeln('done: ${specs.length} sheets');
}

void drawFrame(img.Image sheet, AnimSpec spec, int frame, int ox) {
  final t = spec.frames == 1 ? 0.0 : frame / (spec.frames - 1);
  final body = img.ColorRgba8(spec.r, spec.g, spec.b, 255);
  final dark = img.ColorRgba8(
      (spec.r * 0.55).round(), (spec.g * 0.55).round(), (spec.b * 0.55).round(), 255);
  final skin = img.ColorRgba8(225, 205, 180, 255);
  final faint = img.ColorRgba8(255, 255, 255, 40);

  // Cell border + anim/frame label for alignment debugging.
  img.drawRect(sheet,
      x1: ox, y1: 0, x2: ox + cell - 1, y2: cell - 1, color: faint);
  img.drawString(sheet, '${spec.key} $frame',
      font: img.arial24, x: ox + 14, y: 12, color: faint);

  void rect(num x1, num y1, num x2, num y2, img.Color c) {
    img.fillRect(sheet,
        x1: ox + x1.round(), y1: y1.round(), x2: ox + x2.round(),
        y2: y2.round(), color: c);
  }

  void circle(num cx, num cy, int radius, img.Color c) {
    img.fillCircle(sheet,
        x: ox + cx.round(), y: cy.round(), radius: radius, color: c);
  }

  switch (spec.key) {
    case 'knockdown':
    case 'defeat':
      // Standing -> lying on the floor, sliding backwards.
      final lie = t;
      final torsoY = feetY - 330 + (lie * 290);
      final shift = -lie * 120;
      rect(216 + shift, torsoY, 296 + shift + lie * 120, torsoY + 160 - lie * 110, body);
      circle(256 + shift - lie * 130, torsoY - 30 + lie * 40, 38, skin);
      rect(236 + shift + lie * 60, torsoY + 150 - lie * 100, 276 + shift + lie * 200, feetY, dark);
      break;

    case 'get_up':
      // Lying -> standing.
      final rise = 1 - t;
      final torsoY = feetY - 330 + (rise * 290);
      final shift = -rise * 120;
      rect(216 + shift, torsoY, 296 + shift + rise * 120, torsoY + 160 - rise * 110, body);
      circle(256 + shift - rise * 130, torsoY - 30 + rise * 40, 38, skin);
      rect(236 + shift + rise * 60, torsoY + 150 - rise * 100, 276 + shift + rise * 200, feetY, dark);
      break;

    case 'crouch':
    case 'block_low':
      final sink = 110 * math.min(1.0, t * 2 + 0.4);
      rect(212, 300 + sink, 300, 430 + sink * 0.6, body);
      circle(256, 260 + sink, 38, skin);
      rect(222, 420 + sink * 0.6, 290, feetY, dark);
      if (spec.key == 'block_low') {
        rect(300, 280 + sink, 340, 420 + sink * 0.5, dark);
      }
      break;

    default:
      _drawStanding(spec, frame, t, rect, circle, body, dark, skin);
  }
}

void _drawStanding(
  AnimSpec spec,
  int frame,
  double t,
  void Function(num, num, num, num, img.Color) rect,
  void Function(num, num, int, img.Color) circle,
  img.Color body,
  img.Color dark,
  img.Color skin,
) {
  final phase = math.sin(2 * math.pi * t);
  var bob = 0.0;
  var legSplit = 0.0;
  var headShift = 0.0;
  var feetLift = 0.0;

  switch (spec.key) {
    case 'idle':
      bob = phase * 6;
    case 'walk_forward':
    case 'walk_backward':
      legSplit = phase * 26;
      bob = phase.abs() * 4;
    case 'jump_up':
    case 'jump_forward':
      feetLift = 50;
      headShift = spec.key == 'jump_forward' ? 24 : 0;
    case 'hit':
      headShift = -30 - t * 20;
      bob = t * 10;
    case 'victory':
      bob = -phase.abs() * 8;
  }

  final hipY = 330.0 + bob;
  // Legs.
  rect(230 + legSplit, hipY, 258 + legSplit, feetY - feetLift, dark);
  rect(258 - legSplit, hipY, 286 - legSplit, feetY - feetLift, dark);
  // Torso.
  rect(216 + headShift * 0.3, 170 + bob, 296 + headShift * 0.3, hipY + 12, body);
  // Head.
  circle(256 + headShift, 130 + bob, 38, skin);

  // Arms per animation.
  switch (spec.key) {
    case 'punch_combo':
      final local = frame % 4;
      final ext = 60 + (local / 3) * 130;
      final armY = frame < 4 ? 230.0 : 200.0;
      rect(290, armY, 290 + ext, armY + 34, skin);
    case 'kick_combo':
      final local = frame % 8;
      final ext = 40 + math.sin(math.pi * local / 7) * 200;
      rect(280, 320, 280 + ext, 360, dark);
      rect(196, 210, 226, 320, skin);
    case 'special_attack':
      rect(290, 220, 420, 254, skin);
      circle(430 + t * 60, 237, (18 + t * 22).round(), body);
    case 'block_high':
      rect(292, 150, 336, 330, dark);
    case 'victory':
      rect(290, 60, 324, 230, skin);
    case 'finisher':
      final swing = math.sin(math.pi * t);
      rect(290, 90 + swing * 160, 324 + swing * 140, 130 + swing * 170, skin);
      circle(256, 130, 44, body);
    default:
      rect(196, 200, 222, 330, skin);
      rect(290, 200, 316, 330, skin);
  }
}
