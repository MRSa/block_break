import 'package:block_break/ui/title_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Title screen shows title and start button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TitleScreen()));

    expect(find.text('ブロック崩し'), findsOneWidget);
    expect(find.text('スタート'), findsOneWidget);
  });

  testWidgets('Start button navigates to game screen with launch button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TitleScreen()));

    await tester.tap(find.text('スタート'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // ゲーム画面の HUD
    expect(find.text('SCORE 0'), findsOneWidget);
    expect(find.text('LEVEL 1'), findsOneWidget);
    expect(find.text('LIVES 3'), findsOneWidget);
    // 発射ボタン
    expect(find.text('発射'), findsOneWidget);
  });

  testWidgets('Tapping launch button starts the game', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TitleScreen()));

    await tester.tap(find.text('スタート'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 発射ボタンが存在することを確認
    expect(find.text('発射'), findsOneWidget);

    // 発射ボタンをタップ
    await tester.tap(find.text('発射'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // ボールが発射されるため発射ボタンは消える
    expect(find.text('発射'), findsNothing);
    // ゲームオーバーもレベルクリアでもない（playing 中）
    expect(find.text('GAME OVER'), findsNothing);
    expect(find.text('LEVEL CLEAR!'), findsNothing);
  });
}
