import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/painting.dart' show Canvas, FilterQuality, Paint;

import 'iron_omen_game.dart';

class _EffectSpec {
  const _EffectSpec(this.file, this.cell, this.frames, this.ticksPerFrame);

  final String file;
  final double cell;
  final int frames;
  final int ticksPerFrame;
}

class _ActiveEffect {
  _ActiveEffect(
      this.key, this.spec, this.x, this.y, this.size, this.flip, this.startTick);

  final String key;
  final _EffectSpec spec;
  final double x;
  final double y;
  final double size;
  final bool flip;
  final int startTick;
}

/// One-shot combat VFX (hit sparks, block sparks, blood bursts, smears),
/// pooled into a single world component. Purely visual: effects advance on
/// the logic tick count so they freeze naturally during hitstop, exactly
/// like the fighters.
class EffectsRenderer extends Component with HasGameReference<IronOmenGame> {
  static const Map<String, _EffectSpec> _specs = {
    'hit_spark': _EffectSpec('fx/hit_spark.png', 48, 7, 2),
    'block_spark': _EffectSpec('fx/block_spark.png', 48, 7, 2),
    'smear': _EffectSpec('fx/smear.png', 48, 5, 2),
    'blood_burst': _EffectSpec('fx/blood_burst.png', 194, 8, 3),
  };

  final Map<String, List<Sprite>> _frames = {};
  final List<_ActiveEffect> _active = [];

  static final Paint _pixelPaint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  @override
  Future<void> onLoad() async {
    for (final entry in _specs.entries) {
      final image = await game.images.load(entry.value.file);
      final sheet =
          SpriteSheet(image: image, srcSize: Vector2.all(entry.value.cell));
      _frames[entry.key] = [
        for (var i = 0; i < entry.value.frames; i++) sheet.getSprite(0, i),
      ];
    }
  }

  /// Spawns effect [key] centered at world ([x], [y]).
  void spawn(String key, double x, double y,
      {double size = 240, bool flip = false}) {
    final spec = _specs[key];
    if (spec == null) return;
    _active
        .add(_ActiveEffect(key, spec, x, y, size, flip, game.ticker.tickCount));
  }

  @override
  void render(Canvas canvas) {
    final now = game.ticker.tickCount;
    _active.removeWhere(
        (e) => now - e.startTick >= e.spec.frames * e.spec.ticksPerFrame);
    for (final effect in _active) {
      final index =
          ((now - effect.startTick) ~/ effect.spec.ticksPerFrame)
              .clamp(0, effect.spec.frames - 1);
      final sprite = _frames[effect.key];
      if (sprite == null) continue;
      canvas.save();
      canvas.translate(effect.x, effect.y);
      if (effect.flip) canvas.scale(-1, 1);
      sprite[index].render(
        canvas,
        position: Vector2(-effect.size / 2, -effect.size / 2),
        size: Vector2.all(effect.size),
        overridePaint: _pixelPaint,
      );
      canvas.restore();
    }
  }
}
