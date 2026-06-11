import 'package:flame/cache.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';

import '../../core/constants/asset_paths.dart';
import '../combat/move_data.dart';
import 'fighter_data.dart';
import 'fighter_state.dart';

/// Loads a fighter's sprite sheets (one horizontal 512x512 strip per
/// animation) and resolves the exact sprite frame for a state + tick.
/// Attack animations are paced by their move's tick counts so the art always
/// matches startup/active/recovery.
class FighterAnimationManager {
  FighterAnimationManager(this.data);

  final FighterData data;
  final Map<String, List<Sprite>> _frames = {};

  /// Preloads every sheet; called at fighter-select time, never mid-match.
  Future<void> load(Images images) async {
    for (final def in data.animations.values) {
      final image =
          await images.load(AssetPaths.fighterAnimation(data.id, def.key));
      final sheet =
          SpriteSheet(image: image, srcSize: Vector2.all(data.frameSize));
      _frames[def.key] = [
        for (var i = 0; i < def.frameCount; i++) sheet.getSprite(0, i),
      ];
    }
  }

  /// Sprite to draw for the given FSM state. [move] must be the current
  /// move when [state] is an attack state.
  Sprite spriteFor(FighterState state, int stateTick, MoveData? move) {
    if (state.isAttacking && move != null) {
      return _attackSprite(move, stateTick);
    }
    final key = data.stateAnimation[state] ?? 'idle';
    final def = data.animationByKey(key);
    final frames = _framesFor(key);
    final rawIndex = stateTick ~/ def.ticksPerFrame;
    final index = def.loop
        ? rawIndex % def.frameCount
        : rawIndex.clamp(0, def.frameCount - 1);
    return frames[index];
  }

  Sprite _attackSprite(MoveData move, int moveTick) {
    final frames = _framesFor(move.animation);
    final frameCount = move.animEndFrame - move.animStartFrame + 1;
    final progress = (moveTick / move.totalTicks).clamp(0.0, 0.999);
    final index = move.animStartFrame + (progress * frameCount).floor();
    return frames[index.clamp(0, frames.length - 1)];
  }

  List<Sprite> _framesFor(String key) {
    final frames = _frames[key];
    if (frames == null) {
      throw StateError(
          'Animation "$key" for ${data.id} not loaded — call load() first');
    }
    return frames;
  }
}
