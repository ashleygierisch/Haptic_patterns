import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_patterns_example/main.dart';

void main() {
  testWidgets('renders play buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.widgetWithText(ElevatedButton, 'Play tap'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Play pattern'), findsOneWidget);
  });
}
