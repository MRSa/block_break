import 'dart:ui';

import 'package:block_break/game/collision.dart';
import 'package:block_break/game/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('circleRectCollision', () {
    test('衝突なし', () {
      final c = circleRectCollision(Offset(10, 10), 5, Rect.fromLTWH(100, 100, 50, 30));
      expect(c, isNull);
    });

    test('矩形内部の中心から衝突', () {
      final c = circleRectCollision(Offset(120, 110), 5, Rect.fromLTWH(100, 100, 50, 30));
      expect(c, isNotNull);
    });

    test('角の接触', () {
      // 矩形右上角 (150,100) に半径5の円が距離3-4で接触
      final c = circleRectCollision(Offset(153, 97), 5, Rect.fromLTWH(100, 100, 50, 30));
      expect(c, isNotNull);
    });

    test('角の非接触', () {
      final c = circleRectCollision(Offset(160, 90), 5, Rect.fromLTWH(100, 100, 50, 30));
      expect(c, isNull);
    });
  });

  group('wallBounce', () {
    test('左壁で反射', () {
      final ball = Ball(position: Offset(5, 100), velocity: Offset(-100, 50));
      final v = wallBounce(ball, Size(400, 600));
      expect(v, Offset(100, 50));
    });

    test('右壁で反射', () {
      final ball = Ball(position: Offset(395, 100), velocity: Offset(100, 50));
      final v = wallBounce(ball, Size(400, 600));
      expect(v, Offset(-100, 50));
    });

    test('天井で反射', () {
      final ball = Ball(position: Offset(100, 5), velocity: Offset(50, -100));
      final v = wallBounce(ball, Size(400, 600));
      expect(v, Offset(50, 100));
    });

    test('下部は落下(反射なし)', () {
      final ball = Ball(position: Offset(100, 595), velocity: Offset(50, 100));
      final v = wallBounce(ball, Size(400, 600));
      expect(v, isNull);
    });

    test('壁外へ向かっていない場合は反射しない', () {
      final ball = Ball(position: Offset(5, 100), velocity: Offset(100, 50));
      final v = wallBounce(ball, Size(400, 600));
      expect(v, isNull);
    });
  });

  group('blockBounce', () {
    test('上面衝突で Y 方向反転', () {
      final ball = Ball(position: Offset(125, 95), velocity: Offset(0, 100));
      final block = Block(rect: Rect.fromLTWH(100, 100, 50, 30), hits: 1);
      expect(blockBounce(ball, block), isTrue);
      expect(ball.velocity, Offset(0, -100));
      expect(ball.position.dy, lessThanOrEqualTo(100 - ball.radius));
    });

    test('下面衝突で Y 方向反転', () {
      final ball = Ball(position: Offset(125, 135), velocity: Offset(0, -100));
      final block = Block(rect: Rect.fromLTWH(100, 100, 50, 30), hits: 1);
      expect(blockBounce(ball, block), isTrue);
      expect(ball.velocity, Offset(0, 100));
    });

    test('左面衝突で X 方向反転', () {
      final ball = Ball(position: Offset(95, 115), velocity: Offset(100, 0));
      final block = Block(rect: Rect.fromLTWH(100, 100, 50, 30), hits: 1);
      expect(blockBounce(ball, block), isTrue);
      expect(ball.velocity, Offset(-100, 0));
    });

    test('非衝突', () {
      final ball = Ball(position: Offset(200, 200), velocity: Offset(100, 0));
      final block = Block(rect: Rect.fromLTWH(100, 100, 50, 30), hits: 1);
      expect(blockBounce(ball, block), isFalse);
    });
  });

  group('paddleReflectVelocity', () {
    test('中央命中は真上', () {
      final paddle = Paddle(x: 200, y: 500);
      final v = paddleReflectVelocity(Offset(200, 500), paddle, 300);
      expect(v.dx, closeTo(0, 1e-9));
      expect(v.dy, closeTo(-300, 1e-9));
    });

    test('右端命中は右上60度', () {
      final paddle = Paddle(x: 200, y: 500);
      final v = paddleReflectVelocity(Offset(260, 500), paddle, 300);
      expect(v.dx, greaterThan(0));
      expect(v.dy, lessThan(0));
      expect(v.distance, closeTo(300, 1e-6));
    });

    test('左端命中は左上60度', () {
      final paddle = Paddle(x: 200, y: 500);
      final v = paddleReflectVelocity(Offset(140, 500), paddle, 300);
      expect(v.dx, lessThan(0));
      expect(v.dy, lessThan(0));
    });

    test('端外は clamp される', () {
      final paddle = Paddle(x: 200, y: 500);
      final v = paddleReflectVelocity(Offset(400, 500), paddle, 300);
      expect(v.dx, greaterThan(0));
      expect(v.dy, lessThan(0));
    });
  });
}