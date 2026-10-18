import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_state.dart';
import 'game_canvas.dart' show blockColor;

String _highScoreKey(int level) => 'hiscore_level_$level';

class GameScreen extends StatefulWidget {
  final int startLevel;

  const GameScreen({super.key, this.startLevel = 1});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final GameState _state = GameState();
  late final Ticker _ticker;
  DateTime? _lastTime;
  GameStatus? _prevStatus;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _state.startLevel = widget.startLevel;
    _state.addListener(_onStateChanged);
    _ticker = createTicker(_tick)..start();
    _loadHighScore();
  }

  void _onStateChanged() {
    final cur = _state.status;
    if (_prevStatus == GameStatus.playing &&
        (cur == GameStatus.levelClear || cur == GameStatus.gameOver)) {
      _saveHighScore(_state.level + 1, _state.score);
    }
    _prevStatus = cur;
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_highScoreKey(_state.level + 1)) ?? 0;
    if (mounted) setState(() => _highScore = v);
  }

  Future<void> _saveHighScore(int level, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _highScoreKey(level);
    final cur = prefs.getInt(key) ?? 0;
    if (score > cur) {
      await prefs.setInt(key, score);
      if (mounted && level == _state.level + 1) {
        setState(() => _highScore = score);
      }
    }
  }

  void _tick(Duration elapsed) {
    final now = DateTime.now();
    final last = _lastTime;
    if (last == null) {
      _lastTime = now;
      return;
    }
    final dt = now.difference(last).inMicroseconds / 1e6;
    _lastTime = now;
    if (_state.size.width > 0) {
      _state.update(dt.clamp(0, 1 / 30));
    }
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _ticker.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      if (event is KeyDownEvent) {
        _state.leftPressed = true;
      } else if (event is KeyUpEvent) {
        _state.leftPressed = false;
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      if (event is KeyDownEvent) {
        _state.rightPressed = true;
      } else if (event is KeyUpEvent) {
        _state.rightPressed = false;
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW) {
      if (event is KeyDownEvent) {
        _state.upPressed = true;
      } else if (event is KeyUpEvent) {
        _state.upPressed = false;
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      if (event is KeyDownEvent) {
        _state.downPressed = true;
      } else if (event is KeyUpEvent) {
        _state.downPressed = false;
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) {
        if (_state.status == GameStatus.ready) {
          _state.launch();
        } else if (_state.status == GameStatus.gameOver) {
          _state.restart();
        }
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF101826),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            if (_state.size.width <= 0) {
              // 初回ビルドで即座に初期化（notify しないため builder 内で安全）。
              // 初回描画でブロック・パドル・ボールが描画される。
              _state.initializeSize(size);
            }
            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerMove: (e) =>
                  _state.movePaddleTo(e.position.dx, e.position.dy),
              onPointerDown: (e) {
                _state.movePaddleTo(e.position.dx, e.position.dy);
                if (_state.status == GameStatus.ready) {
                  _state.launch();
                }
              },
              child: Stack(
                children: [
                  // ゲーム要素（ブロック・パドル・ボール）
                  // 標準 Flutter ウィジェットで描画（CustomPaint / Impeller 描画問題を回避）
                  AnimatedBuilder(
                    animation: _state,
                    builder: (context, _) => Stack(
                      children: [
                        for (final b in _state.blocks)
                          if (b.alive)
                            Positioned(
                              left: b.rect.left,
                              top: b.rect.top,
                              width: b.rect.width,
                              height: b.rect.height,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: blockColor(b.hits),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: b.maxHits > 1
                                    ? Center(
                                        child: Text(
                                          b.hits.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                        Positioned(
                          left: _state.paddle.x - _state.paddle.width / 2,
                          top: _state.paddle.y,
                          width: _state.paddle.width,
                          height: _state.paddle.height,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Positioned(
                          left:
                              _state.ball.position.dx - _state.ball.radius,
                          top:
                              _state.ball.position.dy - _state.ball.radius,
                          width: _state.ball.radius * 2,
                          height: _state.ball.radius * 2,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFF176),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // HUD
                  Positioned(
                    top: 8,
                    left: 12,
                    child: AnimatedBuilder(
                      animation: _state,
                      builder: (context, _) => Row(
                        children: [
                          _hudChip('SCORE ${_state.score}'),
                          const SizedBox(width: 8),
                          _hudChip('LEVEL ${_state.level + 1}'),
                          const SizedBox(width: 8),
                          _hudChip('LIVES ${_state.lives}'),
                          const SizedBox(width: 8),
                          _hudChip('BEST $_highScore'),
                        ],
                      ),
                    ),
                  ),
                  // オーバーレイ
                  AnimatedBuilder(
                    animation: _state,
                    builder: (context, _) => _overlay(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _hudChip(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _overlay(BuildContext context) {
    switch (_state.status) {
      case GameStatus.ready:
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ブロック崩し',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'パドルをドラッグで移動・ボールを反射させてブロックを壊そう',
                  style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC3F7),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _state.launch,
                    child: const Text(
                      '発射',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'または SPACE / タップで発射',
                  style: TextStyle(color: Color(0xFF78909C), fontSize: 12),
                ),
              ],
            ),
          ),
        );
      case GameStatus.gameOver:
        return _centerPanel(
          title: 'GAME OVER',
          subtitle: 'SCORE ${_state.score}',
          buttonLabel: 'RESTART',
          onTap: _state.restart,
        );
      case GameStatus.levelClear:
        return _centerPanel(
          title: 'LEVEL CLEAR!',
          subtitle: 'SCORE ${_state.score}',
          buttonLabel: 'NEXT LEVEL',
          onTap: _state.nextLevel,
        );
      case GameStatus.playing:
        return const SizedBox.shrink();
    }
  }

  Widget _centerPanel({
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xE6000000),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onTap,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}