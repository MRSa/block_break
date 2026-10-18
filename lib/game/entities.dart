import 'dart:math';
import 'dart:ui';

/// ボール
class Ball {
  Offset position;
  Offset velocity; // px/s
  final double radius;

  Ball({
    required this.position,
    Offset? velocity,
    this.radius = 10,
  }) : velocity = velocity ?? Offset.zero;
}

/// パドル
class Paddle {
  double x; // 中心 x
  double y; // 上辺 y（可変：上下移動に対応）
  final double width;
  final double height;

  Paddle({
    required this.x,
    required this.y,
    this.width = 120,
    this.height = 16,
  });

  Rect get rect => Rect.fromLTWH(x - width / 2, y, width, height);
}

/// ブロック
class Block {
  final Rect rect;
  int hits; // 残り耐久値
  final int maxHits;
  bool alive = true;

  Block({required this.rect, required this.hits}) : maxHits = hits;
}

/// パドル反射: 当たる位置により反射角を決定 (-60°〜60°)
Offset paddleReflectVelocity(Offset center, Paddle paddle, double speed) {
  final rel = ((center.dx - paddle.x) / (paddle.width / 2)).clamp(-1.0, 1.0);
  final theta = -pi / 2 + rel * (pi / 3);
  return Offset(speed * cos(theta), speed * sin(theta));
}