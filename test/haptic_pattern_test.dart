import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_patterns/haptic_patterns.dart';

void main() {
  group('HapticEvent', () {
    test('default values', () {
      const event = HapticEvent();
      expect(event.intensity, 1.0);
      expect(event.sharpness, 0.5);
      expect(event.duration, Duration.zero);
    });

    test('tap preset', () {
      const event = HapticEvent.tap();
      expect(event.intensity, 0.6);
      expect(event.sharpness, 0.7);
      expect(event.duration, Duration.zero);
    });

    test('thud preset', () {
      const event = HapticEvent.thud();
      expect(event.intensity, 1.0);
      expect(event.sharpness, 0.2);
    });

    test('buzz preset has a nonzero duration', () {
      const event = HapticEvent.buzz();
      expect(event.intensity, 0.8);
      expect(event.sharpness, 0.4);
      expect(event.duration, const Duration(milliseconds: 200));
    });

    test('presets accept overrides', () {
      const event = HapticEvent.tap(intensity: 0.1, sharpness: 0.9);
      expect(event.intensity, 0.1);
      expect(event.sharpness, 0.9);
    });

    test('rejects intensity out of range', () {
      expect(() => HapticEvent(intensity: 1.1), throwsA(isA<AssertionError>()));
      expect(() => HapticEvent(intensity: -0.1), throwsA(isA<AssertionError>()));
    });

    test('rejects sharpness out of range', () {
      expect(() => HapticEvent(sharpness: 1.1), throwsA(isA<AssertionError>()));
      expect(() => HapticEvent(sharpness: -0.1), throwsA(isA<AssertionError>()));
    });

    test('boundary values 0.0 and 1.0 are allowed', () {
      expect(() => const HapticEvent(intensity: 0.0, sharpness: 0.0), returnsNormally);
      expect(() => const HapticEvent(intensity: 1.0, sharpness: 1.0), returnsNormally);
    });

    test('compiles to a single instruction with no delay', () {
      const event = HapticEvent(intensity: 0.5, sharpness: 0.3, duration: Duration(milliseconds: 40));
      final compiled = event.compile();
      expect(compiled, [
        const HapticInstruction(intensity: 0.5, sharpness: 0.3, durationMs: 40, delayMs: 0),
      ]);
    });

    test('equality is value-based', () {
      expect(const HapticEvent(intensity: 0.5), const HapticEvent(intensity: 0.5));
      expect(const HapticEvent(intensity: 0.5), isNot(const HapticEvent(intensity: 0.6)));
    });
  });

  group('HapticDelay', () {
    test('stores duration', () {
      const d = HapticDelay(Duration(milliseconds: 75));
      expect(d.duration, const Duration(milliseconds: 75));
    });

    test('zero duration is allowed', () {
      expect(() => const HapticDelay(Duration.zero), returnsNormally);
    });

    test('compiles to no instructions on its own', () {
      const d = HapticDelay(Duration(milliseconds: 50));
      expect(d.compile(), isEmpty);
    });

    test('equality is value-based', () {
      expect(
        const HapticDelay(Duration(milliseconds: 10)),
        const HapticDelay(Duration(milliseconds: 10)),
      );
    });
  });

  group('delay()', () {
    test('creates a HapticDelay from milliseconds', () {
      final d = delay(50);
      expect(d, const HapticDelay(Duration(milliseconds: 50)));
    });
  });

  group('HapticSequence.compile', () {
    test('empty sequence compiles to nothing', () {
      expect(const HapticSequence([]).compile(), isEmpty);
    });

    test('single event with no delays', () {
      final compiled = HapticSequence([HapticEvent.tap()]).compile();
      expect(compiled.length, 1);
      expect(compiled[0].delayMs, 0);
    });

    test('two events with a delay between them', () {
      final compiled = HapticSequence([
        HapticEvent.tap(),
        delay(50),
        HapticEvent.tap(),
      ]).compile();

      expect(compiled.length, 2);
      expect(compiled[0].delayMs, 0);
      expect(compiled[1].delayMs, 50);
    });

    test('leading delay applies to the first instruction', () {
      final compiled = HapticSequence([delay(30), HapticEvent.tap()]).compile();
      expect(compiled.length, 1);
      expect(compiled[0].delayMs, 30);
    });

    test('trailing delay with nothing after it has no effect', () {
      // A delay only has meaning as a gap before whatever plays next.
      // With nothing following it, it's dropped -- documented, defined
      // behavior, not an oversight.
      final compiled = HapticSequence([HapticEvent.tap(), delay(30)]).compile();
      expect(compiled.length, 1);
      expect(compiled[0].delayMs, 0);
    });

    test('consecutive delays sum together', () {
      final compiled = HapticSequence([
        HapticEvent.tap(),
        delay(20),
        delay(30),
        HapticEvent.tap(),
      ]).compile();

      expect(compiled.length, 2);
      expect(compiled[1].delayMs, 50);
    });

    test('nested sequences flatten correctly', () {
      final compiled = HapticSequence([
        HapticEvent.tap(),
        HapticSequence([delay(10), HapticEvent.tap()]),
        HapticEvent.tap(),
      ]).compile();

      expect(compiled.length, 3);
      expect(compiled[0].delayMs, 0);
      expect(compiled[1].delayMs, 10);
      expect(compiled[2].delayMs, 0);
    });

    test('outer delay combines with a nested sequence\'s own leading delay', () {
      final compiled = HapticSequence([
        HapticEvent.tap(),
        delay(5),
        HapticSequence([delay(10), HapticEvent.tap()]),
      ]).compile();

      expect(compiled.length, 2);
      expect(compiled[1].delayMs, 15);
    });

    test('preserves intensity/sharpness/duration from each event', () {
      final compiled = HapticSequence([
        HapticEvent.tap(),
        HapticEvent.buzz(),
      ]).compile();

      expect(compiled[0].intensity, HapticEvent.tap().intensity);
      expect(compiled[1].intensity, HapticEvent.buzz().intensity);
      expect(compiled[1].durationMs, HapticEvent.buzz().duration.inMilliseconds);
    });

    test('a sequence of only delays compiles to nothing', () {
      final compiled = HapticSequence([delay(10), delay(20)]).compile();
      expect(compiled, isEmpty);
    });
  });

  group('HapticInstruction', () {
    test('toMap produces the expected keys', () {
      const instruction = HapticInstruction(intensity: 0.5, sharpness: 0.6, durationMs: 10, delayMs: 20);
      expect(instruction.toMap(), {
        'intensity': 0.5,
        'sharpness': 0.6,
        'durationMs': 10,
        'delayMs': 20,
      });
    });

    test('equality is value-based', () {
      const a = HapticInstruction(intensity: 0.5, sharpness: 0.6, durationMs: 10, delayMs: 20);
      const b = HapticInstruction(intensity: 0.5, sharpness: 0.6, durationMs: 10, delayMs: 20);
      const c = HapticInstruction(intensity: 0.9, sharpness: 0.6, durationMs: 10, delayMs: 20);
      expect(a, b);
      expect(a, isNot(c));
    });
  });
}
