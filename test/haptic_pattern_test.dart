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

    test('equal instances share a hashCode', () {
      expect(
        const HapticEvent(intensity: 0.5, sharpness: 0.3).hashCode,
        const HapticEvent(intensity: 0.5, sharpness: 0.3).hashCode,
      );
    });

    test('toString includes intensity, sharpness, and duration', () {
      const event = HapticEvent(
        intensity: 0.5,
        sharpness: 0.3,
        duration: Duration(milliseconds: 40),
      );
      expect(event.toString(), contains('0.5'));
      expect(event.toString(), contains('0.3'));
      expect(event.toString(), contains('0:00:00.040000'));
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

    test('equal instances share a hashCode', () {
      expect(
        const HapticDelay(Duration(milliseconds: 10)).hashCode,
        const HapticDelay(Duration(milliseconds: 10)).hashCode,
      );
    });

    test('toString includes the duration', () {
      expect(const HapticDelay(Duration(milliseconds: 50)).toString(), contains('0:00:00.050000'));
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

  group('HapticSequence', () {
    test('toString includes its patterns', () {
      final sequence = HapticSequence([HapticEvent.tap(), delay(50)]);
      expect(sequence.toString(), contains('HapticSequence'));
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

    test('equal instances share a hashCode', () {
      const a = HapticInstruction(intensity: 0.5, sharpness: 0.6, durationMs: 10, delayMs: 20);
      const b = HapticInstruction(intensity: 0.5, sharpness: 0.6, durationMs: 10, delayMs: 20);
      expect(a.hashCode, b.hashCode);
    });

    test('toString includes all four fields', () {
      const instruction = HapticInstruction(intensity: 0.5, sharpness: 0.6, durationMs: 10, delayMs: 20);
      final string = instruction.toString();
      expect(string, allOf(contains('0.5'), contains('0.6'), contains('10'), contains('20')));
    });
  });

  group('HapticRepeat', () {
    test('rejects negative count', () {
      expect(
        () => HapticRepeat(HapticEvent.tap(), count: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('count of zero compiles to nothing', () {
      final compiled = const HapticRepeat(HapticEvent.tap(), count: 0).compile();
      expect(compiled, isEmpty);
    });

    test('count of one compiles to a single cycle with no gap applied', () {
      final compiled = const HapticRepeat(HapticEvent.tap(), count: 1).compile();
      expect(compiled, hasLength(1));
      expect(compiled[0].delayMs, 0);
    });

    test('repeats a single-instruction pattern with gap between cycles', () {
      final compiled = const HapticRepeat(
        HapticEvent.tap(),
        count: 3,
        gap: Duration(milliseconds: 50),
      ).compile();

      expect(compiled, hasLength(3));
      expect(compiled[0].delayMs, 0);
      expect(compiled[1].delayMs, 50);
      expect(compiled[2].delayMs, 50);
    });

    test('gap defaults to zero', () {
      final compiled = const HapticRepeat(HapticEvent.tap(), count: 2).compile();
      expect(compiled[1].delayMs, 0);
    });

    test('repeats a multi-instruction pattern, gap only before each cycle', () {
      final subPattern = HapticSequence([HapticEvent.tap(), delay(10), HapticEvent.tap()]);
      final compiled = HapticRepeat(
        subPattern,
        count: 2,
        gap: const Duration(milliseconds: 100),
      ).compile();

      // Cycle 1: [delay 0, delay 10]. Cycle 2: [delay 100, delay 10] --
      // the 100ms gap lands on the first instruction of cycle 2, not
      // between the two instructions inside a single cycle.
      expect(compiled, hasLength(4));
      expect(compiled[0].delayMs, 0);
      expect(compiled[1].delayMs, 10);
      expect(compiled[2].delayMs, 100);
      expect(compiled[3].delayMs, 10);
    });

    test('repeating an empty pattern compiles to nothing regardless of count', () {
      final compiled = HapticRepeat(const HapticSequence([]), count: 5).compile();
      expect(compiled, isEmpty);
    });

    test('preserves intensity/sharpness/duration across every repetition', () {
      final compiled = const HapticRepeat(
        HapticEvent(intensity: 0.7, sharpness: 0.3, duration: Duration(milliseconds: 40)),
        count: 3,
      ).compile();

      for (final instruction in compiled) {
        expect(instruction.intensity, 0.7);
        expect(instruction.sharpness, 0.3);
        expect(instruction.durationMs, 40);
      }
    });

    test('nests correctly inside a HapticSequence', () {
      final compiled = HapticSequence([
        const HapticRepeat(HapticEvent.tap(), count: 2, gap: Duration(milliseconds: 20)),
        delay(30),
        HapticEvent.tap(),
      ]).compile();

      expect(compiled, hasLength(3));
      expect(compiled[0].delayMs, 0);
      expect(compiled[1].delayMs, 20);
      expect(compiled[2].delayMs, 30);
    });

    test('toString includes the pattern, count, and gap', () {
      final repeat = const HapticRepeat(HapticEvent.tap(), count: 3, gap: Duration(milliseconds: 50));
      final string = repeat.toString();
      expect(string, allOf(contains('HapticRepeat'), contains('3'), contains('50')));
    });
  });

  group('HapticCurve', () {
    test('rejects out-of-range startIntensity', () {
      expect(
        () => HapticCurve(startIntensity: 1.1, endIntensity: 0.5, duration: const Duration(milliseconds: 100)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects out-of-range endIntensity', () {
      expect(
        () => HapticCurve(startIntensity: 0.5, endIntensity: -0.1, duration: const Duration(milliseconds: 100)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects out-of-range sharpness', () {
      expect(
        () => HapticCurve(
          startIntensity: 0.5,
          endIntensity: 0.5,
          sharpness: 1.5,
          duration: const Duration(milliseconds: 100),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects fewer than 2 steps', () {
      expect(
        () => HapticCurve(
          startIntensity: 0.0,
          endIntensity: 1.0,
          duration: const Duration(milliseconds: 100),
          steps: 1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('minimum steps (2) produces exactly start and end intensity', () {
      final compiled = const HapticCurve(
        startIntensity: 0.2,
        endIntensity: 0.8,
        duration: Duration(milliseconds: 100),
        steps: 2,
      ).compile();

      expect(compiled, hasLength(2));
      expect(compiled[0].intensity, closeTo(0.2, 0.0001));
      expect(compiled[1].intensity, closeTo(0.8, 0.0001));
    });

    test('default steps produces 10 evenly interpolated instructions', () {
      final compiled = const HapticCurve(
        startIntensity: 0.0,
        endIntensity: 1.0,
        duration: Duration(milliseconds: 100),
      ).compile();

      expect(compiled, hasLength(10));
      expect(compiled.first.intensity, closeTo(0.0, 0.0001));
      expect(compiled.last.intensity, closeTo(1.0, 0.0001));
      // Every intermediate value strictly increases toward the end.
      for (var i = 1; i < compiled.length; i++) {
        expect(compiled[i].intensity, greaterThan(compiled[i - 1].intensity));
      }
    });

    test('descending curve produces strictly decreasing intensity', () {
      final compiled = const HapticCurve(
        startIntensity: 1.0,
        endIntensity: 0.0,
        duration: Duration(milliseconds: 100),
        steps: 5,
      ).compile();

      for (var i = 1; i < compiled.length; i++) {
        expect(compiled[i].intensity, lessThan(compiled[i - 1].intensity));
      }
    });

    test('equal start and end intensity produces a flat curve', () {
      final compiled = const HapticCurve(
        startIntensity: 0.5,
        endIntensity: 0.5,
        duration: Duration(milliseconds: 100),
        steps: 4,
      ).compile();

      for (final instruction in compiled) {
        expect(instruction.intensity, closeTo(0.5, 0.0001));
      }
    });

    test('steps play back-to-back with no gaps', () {
      final compiled = const HapticCurve(
        startIntensity: 0.0,
        endIntensity: 1.0,
        duration: Duration(milliseconds: 100),
      ).compile();

      for (final instruction in compiled) {
        expect(instruction.delayMs, 0);
      }
    });

    test('applies sharpness uniformly across every step', () {
      final compiled = const HapticCurve(
        startIntensity: 0.0,
        endIntensity: 1.0,
        sharpness: 0.9,
        duration: Duration(milliseconds: 100),
      ).compile();

      for (final instruction in compiled) {
        expect(instruction.sharpness, 0.9);
      }
    });

    test('step durations sum close to the total requested duration', () {
      final compiled = const HapticCurve(
        startIntensity: 0.0,
        endIntensity: 1.0,
        duration: Duration(milliseconds: 180),
        steps: 10,
      ).compile();

      final totalMs = compiled.fold<int>(0, (sum, i) => sum + i.durationMs);
      expect(totalMs, 180); // divides evenly: 180 / 10 == 18
    });

    test('nests correctly inside a HapticSequence', () {
      final compiled = HapticSequence([
        HapticEvent.tap(),
        delay(20),
        const HapticCurve(
          startIntensity: 0.5,
          endIntensity: 0.0,
          duration: Duration(milliseconds: 40),
          steps: 2,
        ),
      ]).compile();

      expect(compiled, hasLength(3));
      expect(compiled[1].delayMs, 20); // gap applies to the curve's first step
      expect(compiled[2].delayMs, 0); // second step of the curve, no added gap
    });

    test('toString includes intensity range, duration, and steps', () {
      final curve = const HapticCurve(
        startIntensity: 0.8,
        endIntensity: 0.0,
        duration: Duration(milliseconds: 200),
        steps: 5,
      );
      final string = curve.toString();
      expect(string, allOf(contains('0.8'), contains('0.0'), contains('5')));
    });
  });
}
