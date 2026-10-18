import 'dart:math';
import 'dart:ui';

import 'entities.dart';

/// 円(ボール)と矩形の衝突判定。
/// 衝突点(矩形上の最近点)を返し、衝突していなければ null。
Offset? circleRectCollision(Offset center, double radius, Rect rect) {
  final closestX = max(rect.left, min(center.dx, rect.right));
  final closestY = max(rect.top, min(center.dy, rect.bottom));
  final dx = center.dx - closestX;
  final dy = center.dy - closestY;
  if (dx * dx + dy * dy <= radius * radius) {
    return Offset(closestX, closestY);
  }
  return null;
}

/// 壁(画面境界)との衝突: 返り値は反射後の速度方向。衝突なしなら null。
Offset? wallBounce(Ball ball, Size field) {
  final r = ball.radius;
  var hit = false;
  var vx = ball.velocity.dx;
  var vy = ball.velocity.dy;

  if (ball.position.dx - r <= 0 && vx < 0) {
    vx = -vx;
    hit = true;
  }
  if (ball.position.dx + r >= field.width && vx > 0) {
    vx = -vx;
    hit = true;
  }
  if (ball.position.dy - r <= 0 && vy < 0) {
    vy = -vy;
    hit = true;
  }
  // 下部は落下扱い(反射しない)
  if (hit) {
    return Offset(vx, vy);
  }
  return null;
}

/// ブロック衝突: 衝突面(法線)に応じて速度を反射する。
/// 衝突した場合は true を返し、ball の速度と位置を修正する。
bool blockBounce(Ball ball, Block block) {
  final contact = circleRectCollision(ball.position, ball.radius, block.rect);
  if (contact == null) return false;

  final center = block.rect.center;
  // 矩形中心から接触点へのベクトルで面を判定
  final dx = contact.dx - center.dx;
  final dy = contact.dy - center.dy;

  if (dx.abs() * block.rect.height > dy.abs() * block.rect.width) {
    // 左右面
    ball.velocity = Offset(-ball.velocity.dx, ball.velocity.dy);
    //  penetration 解消
    if (contact.dx < center.dx) {
      ball.position = Offset(block.rect.left - ball.radius, ball.position.dy);
    } else {
      ball.position = Offset(block.rect.right + ball.radius, ball.position.dy);
    }
  } else {
    // 上下面
    ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy);
    if (contact.dy < center.dy) {
      ball.position = Offset(ball.position.dx, block.rect.top - ball.radius);
    } else {
      ball.position = Offset(ball.position.dx, block.rect.bottom + ball.radius);
    }
  }
  return true;
}