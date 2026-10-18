import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'collision.dart';
import 'entities.dart';

enum GameStatus { ready, playing, gameOver, levelClear }

/// レベルパターン。数字 = 耐久値、'.' = 空き
const List<List<String>> levelPatterns = [
  [
    '11111111',
    '11111111',
    '22222222',
    '22222222',
    '33333333',
  ],
  [
    '3.3.3.3.',
    '.2.2.2.2',
    '3.3.3.3.',
    '.1.1.1.1',
    '3.3.3.3.',
  ],
  [
    '22222222',
    '13333331',
    '22222222',
    '13333331',
    '22222222',
  ],
  [
    '33333333',
    '32222223',
    '32111123',
    '32222223',
    '33333333',
  ],
  [
    '12332112',
    '23311223',
    '33223311',
    '11223322',
    '22331123',
  ],
  [
    '11.11.11',
    '.22.22.2',
    '11.11.11',
    '.22.22.2',
    '11.11.11',
  ],
  [
    '31313131',
    '13131313',
    '31313131',
    '13131313',
    '31313131',
  ],
  [
    '2.2.2.22',
    '.3.3.3.3',
    '2.2.2.22',
    '.3.3.3.3',
    '2.2.2.22',
  ],
  [
    '1111.111',
    '22.22.22',
    '3333.333',
    '22.22.22',
    '1111.111',
  ],
  [
    '32123123',
    '13213213',
    '32123123',
    '13213213',
    '32123123',
  ],
  [
    '13131313',
    '31313131',
    '13131313',
    '31313131',
    '13131313',
  ],
  [
    '22111122',
    '11333311',
    '22111122',
    '11333311',
    '22111122',
  ],
];

class GameState extends ChangeNotifier {
  Size size = Size.zero;
  Ball ball = Ball(position: Offset.zero);
  Paddle paddle = Paddle(x: 0, y: 0);
  List<Block> blocks = [];
  int score = 0;
  int lives = 3;
  int level = 0; // 0-indexed
  int startLevel = 1; // 1-indexed（ユーザー指定開始レベル）
  GameStatus status = GameStatus.ready;
  bool leftPressed = false;
  bool rightPressed = false;
  bool upPressed = false;
  bool downPressed = false;
  final Random rng = Random();

  double get ballSpeed => 300 + level * 40;

  /// パドル幅（難易度に応じて 3 段階: L1-4:120 / L5-8:100 / L9-12:80）
  double get paddleWidth {
    final l = level + 1; // 1-indexed
    if (l <= 4) return 120;
    if (l <= 8) return 100;
    return 80;
  }

  Paddle _makePaddle() =>
      Paddle(x: size.width / 2, y: size.height - 60, width: paddleWidth);

  /// 初回ビルド時に notify せずにサイズ初期化する。
  /// builder 内で安全に呼べる（notifyListeners によるビルド中通知を避ける）。
  void initializeSize(Size s) {
    if (s.width <= 0 || s.height <= 0) return;
    size = s;
    level = startLevel - 1;
    paddle = _makePaddle();
    _buildBlocks();
    _resetBall();
  }

  void setSize(Size s) {
    if (s.width <= 0 || s.height <= 0) return;
    size = s;
    paddle = _makePaddle();
    _buildBlocks();
    _resetBall();
    notifyListeners();
  }

  /// 開始レベルを設定（1-indexed）。ゲーム中ならそのレベルから再開始。
  void setStartLevel(int l) {
    startLevel = l.clamp(1, levelPatterns.length);
    level = startLevel - 1;
    score = 0;
    lives = 3;
    paddle = _makePaddle();
    _buildBlocks();
    _resetBall();
    notifyListeners();
  }

  /// パドル y の可動範囲（画面下 1/3 の領域）
  double get _paddleMinY => size.height - size.height / 3;
  double get _paddleMaxY => size.height - 40;

  void _buildBlocks() {
    final pattern = levelPatterns[level % levelPatterns.length];
    final cols = pattern[0].length;
    final rows = pattern.length;
    final bw = size.width / cols;
    const bh = 30.0;
    blocks = [];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final ch = pattern[r][c];
        if (ch == '.') continue;
        blocks.add(
          Block(
            rect: Rect.fromLTWH(c * bw + 2, 40 + r * bh + 2, bw - 4, bh - 4),
            hits: int.parse(ch),
          ),
        );
      }
    }
  }

  void _resetBall() {
    ball = Ball(position: Offset(paddle.x, paddle.y - ball.radius - 2));
    ball.velocity = Offset.zero;
    status = GameStatus.ready;
  }

  void launch() {
    if (status != GameStatus.ready) return;
    final angle = -pi / 2 + (rng.nextDouble() * 0.6 - 0.3);
    ball.velocity = Offset(ballSpeed * cos(angle), ballSpeed * sin(angle));
    status = GameStatus.playing;
    notifyListeners();
  }

  void movePaddleTo(double x, [double? y]) {
    paddle.x = x.clamp(paddle.width / 2, size.width - paddle.width / 2);
    if (y != null) {
      paddle.y = y.clamp(_paddleMinY, _paddleMaxY);
    }
    if (status == GameStatus.ready) {
      ball.position = Offset(paddle.x, paddle.y - ball.radius - 2);
    }
    notifyListeners();
  }

  void update(double dt) {
    _movePaddleKeyboard(dt);
    if (status != GameStatus.playing) return;

    ball.position += ball.velocity * dt;

    // 壁
    final w = wallBounce(ball, size);
    if (w != null) ball.velocity = w;

    // パドル
    if (ball.velocity.dy > 0 &&
        circleRectCollision(ball.position, ball.radius, paddle.rect) != null) {
      ball.velocity = paddleReflectVelocity(ball.position, paddle, ballSpeed);
      ball.position = Offset(ball.position.dx, paddle.y - ball.radius);
    }

    // ブロック
    for (final b in blocks) {
      if (!b.alive) continue;
      if (blockBounce(ball, b)) {
        b.hits--;
        score += 10;
        if (b.hits <= 0) {
          b.alive = false;
          score += 50;
        }
        break; // 1フレームで1ブロック
      }
    }

    // 落下
    if (ball.position.dy - ball.radius > size.height) {
      lives--;
      if (lives <= 0) {
        status = GameStatus.gameOver;
      } else {
        _resetBall();
      }
    }

    // 全破壊
    if (blocks.every((b) => !b.alive)) {
      status = GameStatus.levelClear;
    }

    notifyListeners();
  }

  void _movePaddleKeyboard(double dt) {
    const v = 600.0;
    if (leftPressed) paddle.x -= v * dt;
    if (rightPressed) paddle.x += v * dt;
    if (upPressed) paddle.y -= v * 0.5 * dt;
    if (downPressed) paddle.y += v * 0.5 * dt;
    paddle.x = paddle.x.clamp(paddle.width / 2, size.width - paddle.width / 2);
    paddle.y = paddle.y.clamp(_paddleMinY, _paddleMaxY);
    if (status == GameStatus.ready) {
      ball.position = Offset(paddle.x, paddle.y - ball.radius - 2);
    }
  }

  void nextLevel() {
    level++;
    paddle = _makePaddle();
    _buildBlocks();
    _resetBall();
    notifyListeners();
  }

  void restart() {
    score = 0;
    lives = 3;
    level = startLevel - 1;
    paddle = _makePaddle();
    _buildBlocks();
    _resetBall();
    notifyListeners();
  }
}