import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_patterns_example/main.dart';

void main() {
  // The example app plays real patterns on tap, which invokes the
  // 'haptic_patterns' method channel. Mock it so those calls resolve
  // instead of throwing MissingPluginException during tests.
  const channel = MethodChannel('haptic_patterns');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async => null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  testWidgets('starts on the keyboard demo', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Q'), findsOneWidget);
    expect(find.text('Type something…'), findsOneWidget);
  });

  testWidgets('typing on the keyboard updates the display text', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('H'));
    await tester.tap(find.text('I'));
    await tester.pump();

    expect(find.text('HI'), findsOneWidget);
  });

  testWidgets('backspace removes the last typed character', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('H'));
    await tester.tap(find.text('I'));
    await tester.tap(find.text('⌫'));
    await tester.pump();

    expect(tester.widget<Text>(find.byKey(const Key('typed-text'))).data, 'H');
  });

  testWidgets('navigating to the playground shows every preset', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Playground'));
    await tester.pumpAndSettle();

    expect(find.text('Custom event'), findsOneWidget);
    expect(find.text('Presets'), findsOneWidget);
    expect(find.byIcon(Icons.vibration), findsWidgets);
  });

  testWidgets('navigating to the game shows score and streak', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Game'));
    await tester.pumpAndSettle();

    expect(find.text('Score'), findsOneWidget);
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('tapping the game target increases the score', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Game'));
    await tester.pumpAndSettle();

    // The target starts centered; its container is 64x64 (radius 32)
    // around the center of the play area.
    await tester.tapAt(tester.getCenter(find.byIcon(Icons.adjust)));
    await tester.pump();

    // Both score and streak advance to 1 on a single hit.
    expect(find.text('1'), findsNWidgets(2));
  });
}
