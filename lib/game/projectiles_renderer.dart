import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/painting.dart' show Canvas, FilterQuality, Paint;

import 'iron_omen_game.dart';

/// Draws every live projectile from the match state. One component renders
/// them all (pooled rendering — no per-projectile component churn).
class ProjectilesRenderer extends Component
    with HasGameReference<IronOmenGame> {
  final Map<String, List<Sprite>> _framesByFighter = {};

  static final Paint _pixelPaint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  /// Preloads the projectile sheet for [fighterId] (4 frames of 64px cells).
  Future<void> loadFor(String fighterId) async {
    if (_framesByFighter.containsKey(fighterId)) return;
    final image =
        await game.images.load('fighters/$fighterId/projectile.png');
    final sheet = SpriteSheet(image: image, srcSize: Vector2.all(64));
    _framesByFighter[fighterId] = [
      for (var i = 0; i < 4; i++) sheet.getSprite(0, i),
    ];
  }

  @override
  void render(Canvas canvas) {
    final alpha = game.ticker.interpolation;
    for (final projectile in game.match.projectiles) {
      final frames = _framesByFighter[projectile.fighterId];
      if (frames == null) continue;
      final sprite = frames[(projectile.ticksAlive ~/ 4) % frames.length];
      final x = projectile.prevX + (projectile.x - projectile.prevX) * alpha;
      final size = projectile.data.renderSize;

      canvas.save();
      canvas.translate(x, projectile.y);
      if (!projectile.facingRight) canvas.scale(-1, 1);
      sprite.render(
        canvas,
        position: Vector2(-size / 2, -size / 2),
        size: Vector2.all(size),
        overridePaint: _pixelPaint,
      );
      canvas.restore();
    }
  }
}
