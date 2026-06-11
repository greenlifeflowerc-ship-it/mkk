import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';

import 'combat/frame_data.dart';
import 'fighter/fighter_component.dart';
import 'iron_omen_game.dart';

/// F1-toggled developer overlay: hurtboxes green, hitboxes red, body boxes
/// blue, plus state/tick/HP labels. Draws the same world-space boxes the
/// collision resolver tests, so what you see is what resolves.
class DebugCombatOverlay extends Component with HasGameReference<IronOmenGame> {
  static final _hurtPaint = Paint()
    ..color = const Color(0xAA00FF66)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final _hitPaint = Paint()..color = const Color(0x66FF2222);
  static final _hitOutline = Paint()
    ..color = const Color(0xFFFF2222)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final _bodyPaint = Paint()
    ..color = const Color(0xAA3399FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  static final _label = TextPaint(
    style: const TextStyle(
      color: Color(0xFFE8E4D8),
      fontSize: 26,
      fontFamily: 'monospace',
    ),
  );

  @override
  void render(Canvas canvas) {
    if (!game.debugCombat) return;
    for (final fighter in game.fighters) {
      _renderFighter(canvas, fighter);
    }
  }

  void _renderFighter(Canvas canvas, FighterComponent fighter) {
    final view = fighter.buildCombatView();
    for (final box in view.worldHurtboxes()) {
      canvas.drawRect(_toRect(box), _hurtPaint);
    }
    for (final box in view.worldHitboxes()) {
      final rect = _toRect(box);
      canvas.drawRect(rect, _hitPaint);
      canvas.drawRect(rect, _hitOutline);
    }
    canvas.drawRect(_toRect(fighter.worldBodyBox()), _bodyPaint);

    final fsm = fighter.fsm;
    _label.render(
      canvas,
      '${fighter.playerId} ${fsm.state.name} t=${fsm.stateTick} '
      'hp=${fighter.health.current}',
      Vector2(fighter.logicX - 180, fighter.logicY - 500),
    );
  }

  Rect _toRect(CombatBox box) =>
      Rect.fromLTWH(box.x, box.y, box.width, box.height);
}
