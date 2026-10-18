import 'package:flutter/material.dart';

import '../game/game_state.dart';

Color blockColor(int hits) {
  switch (hits) {
    case 1:
      return const Color(0xFF4FC3F7);
    case 2:
      return const Color(0xFFFFB74D);
    default:
      return const Color(0xFFEF5350);
  }
}

class GamePainter extends CustomPainter {
  final GameState state;

  GamePainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    // 背景
    canvas.drawRect(
      Offset(0, 0) & size,
      Paint()..color = const Color(0xFF101826),
    );

    // ブロック
    for (final b in state.blocks) {
      if (!b.alive) continue;
      final paint = Paint()
        ..color = blockColor(b.hits)
        ..style = PaintingStyle.fill;
      final rRect = RRect.fromRectAndRadius(b.rect, const Radius.circular(4));
      canvas.drawRRect(rRect, paint);
      // 耐久値テキスト
      if (b.maxHits > 1) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${b.hits}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, b.rect.center - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // パドル
    final paddlePaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(state.paddle.rect, const Radius.circular(8)),
      paddlePaint,
    );

    // ボール
    final ballPaint = Paint()
      ..color = const Color(0xFFFFF176)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(state.ball.position, state.ball.radius, ballPaint);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}