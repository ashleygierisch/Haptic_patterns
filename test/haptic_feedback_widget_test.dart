import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_patterns/haptic_patterns.dart';
import 'package:haptic_patterns/haptic_patterns_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _RecordingPlatform with MockPlatformInterfaceMixin implements HapticPatternsPlatform {
  List<HapticInstruction>? lastPlayed;
  int playCount = 0;

  @override
  Future<void> playInstructions(List<HapticInstruction> instructions) async {
    lastPlayed = instructions;
    playCount++;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<bool> isSupported() async => true;
}

void main() {
  late _RecordingPlatform platform;

  setUp(() {
    platform = _RecordingPlatform();
    HapticPatternsPlatform.instance = platform;
  });

  Widget wrap(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

  testWidgets('renders its child', (tester) async {
    await tester.pumpWidget(
      wrap(const HapticFeedbackWidget(child: Text('hello', textDirection: TextDirection.ltr))),
    );
    expect(find.text('hello'), findsOneWidget);
  });

  group('tap', () {
    testWidgets('plays tapPattern and calls onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          HapticFeedbackWidget(
            tapPattern: HapticEvent.tap(),
            onTap: () => tapped = true,
            child: const ColoredBox(color: Color(0xFF000000), child: SizedBox(width: 50, height: 50)),
          ),
        ),
      );

      await tester.tap(find.byType(HapticFeedbackWidget));
      await tester.pump();

      expect(tapped, isTrue);
      expect(platform.playCount, 1);
      expect(platform.lastPlayed, HapticEvent.tap().compile());
    });

    testWidgets('works with only a callback, no pattern', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          HapticFeedbackWidget(
            onTap: () => tapped = true,
            child: const ColoredBox(color: Color(0xFF000000), child: SizedBox(width: 50, height: 50)),
          ),
        ),
      );

      await tester.tap(find.byType(HapticFeedbackWidget));
      await tester.pump();

      expect(tapped, isTrue);
      expect(platform.playCount, 0);
    });

    testWidgets('works with only a pattern, no callback', (tester) async {
      await tester.pumpWidget(
        wrap(
          HapticFeedbackWidget(
            tapPattern: HapticEvent.tap(),
            child: const ColoredBox(color: Color(0xFF000000), child: SizedBox(width: 50, height: 50)),
          ),
        ),
      );

      await tester.tap(find.byType(HapticFeedbackWidget));
      await tester.pump();

      expect(platform.playCount, 1);
    });

    testWidgets('does nothing when neither pattern nor callback given', (tester) async {
      await tester.pumpWidget(
        wrap(
          const HapticFeedbackWidget(
            child: ColoredBox(color: Color(0xFF000000), child: SizedBox(width: 50, height: 50)),
          ),
        ),
      );

      // Should not throw even though GestureDetector's onTap is null.
      await tester.tap(find.byType(HapticFeedbackWidget));
      await tester.pump();

      expect(platform.playCount, 0);
    });
  });

  group('long press', () {
    testWidgets('plays longPressPattern and calls onLongPress', (tester) async {
      var longPressed = false;
      await tester.pumpWidget(
        wrap(
          HapticFeedbackWidget(
            longPressPattern: HapticPatterns.warning,
            onLongPress: () => longPressed = true,
            child: const ColoredBox(color: Color(0xFF000000), child: SizedBox(width: 50, height: 50)),
          ),
        ),
      );

      await tester.longPress(find.byType(HapticFeedbackWidget));
      await tester.pump();

      expect(longPressed, isTrue);
      expect(platform.playCount, 1);
    });

    testWidgets('a plain tap does not trigger the long-press pattern', (tester) async {
      await tester.pumpWidget(
        wrap(
          HapticFeedbackWidget(
            tapPattern: HapticEvent.tap(),
            longPressPattern: HapticPatterns.warning,
            child: const ColoredBox(color: Color(0xFF000000), child: SizedBox(width: 50, height: 50)),
          ),
        ),
      );

      await tester.tap(find.byType(HapticFeedbackWidget));
      await tester.pump();

      expect(platform.playCount, 1);
      expect(platform.lastPlayed, HapticEvent.tap().compile());
    });
  });

  group('double tap', () {
    testWidgets('plays doubleTapPattern and calls onDoubleTap', (tester) async {
      var doubleTapped = false;
      await tester.pumpWidget(
        wrap(
          HapticFeedbackWidget(
            doubleTapPattern: HapticPatterns.tick,
            onDoubleTap: () => doubleTapped = true,
            child: const ColoredBox(color: Color(0xFF000000), child: SizedBox(width: 50, height: 50)),
          ),
        ),
      );

      // Two taps within the double-tap timing window register as one
      // double-tap gesture; flutter_test has no dedicated doubleTap()
      // helper, so this is the standard way to simulate it.
      await tester.tap(find.byType(HapticFeedbackWidget));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(HapticFeedbackWidget));
      await tester.pumpAndSettle();

      expect(doubleTapped, isTrue);
      expect(platform.playCount, 1);
    });
  });

  testWidgets('behavior is forwarded to the underlying GestureDetector', (tester) async {
    await tester.pumpWidget(
      wrap(
        HapticFeedbackWidget(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: const ColoredBox(color: Color(0xFF000000), child: SizedBox(width: 50, height: 50)),
        ),
      ),
    );

    final detector = tester.widget<GestureDetector>(find.byType(GestureDetector));
    expect(detector.behavior, HitTestBehavior.opaque);
  });
}
