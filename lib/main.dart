import 'package:flutter/material.dart';

import 'ui/title_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BlockBreakApp());
}

class BlockBreakApp extends StatelessWidget {
  const BlockBreakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Break',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4FC3F7)),
        useMaterial3: true,
      ),
      home: const TitleScreen(),
    );
  }
}