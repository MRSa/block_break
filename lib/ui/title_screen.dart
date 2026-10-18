import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_state.dart' show levelPatterns;
import 'game_screen.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  int _level = 1;

  @override
  void initState() {
    super.initState();
    _loadLevel();
  }

  Future<void> _loadLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('start_level') ?? 1;
    if (mounted) {
      setState(() {
        _level = saved.clamp(1, levelPatterns.length);
      });
    }
  }

  Future<void> _saveLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('start_level', level);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101826),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
         children: [
            const Text(
              'ブロック崩し',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            // レベル選択
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '開始: ',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButton<int>(
                    value: _level,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    dropdownColor: const Color(0xFF1E2A3A),
                    borderRadius: BorderRadius.circular(8),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    items: List.generate(
                      levelPatterns.length,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('レベル ${i + 1}'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _level = v);
                      _saveLevel(v);
                    },
                  ),
                ),
              ],
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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GameScreen(startLevel: _level),
                    ),
                  );
                },
                child: const Text(
                  'スタート',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
