import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_patterns/haptic_patterns.dart';
import 'package:haptic_patterns/haptic_patterns_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _RecordingPlatform with MockPlatformInterfaceMixin implements HapticPatternsPlatform {
  List<HapticInstruction>? lastPlayed;

  @override
  Future<void> playInstructions(List<HapticInstruction> instructions) async {
    lastPlayed = instructions;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<bool> isSupported() async => true;
}

void main() {
  group('HapticPatterns.all', () {
    test('contains at least 20 presets', () {
      expect(HapticPatterns.all.length, greaterThanOrEqualTo(20));
    });

    test('every preset compiles to at least one instruction', () {
      for (final entry in HapticPatterns.all.entries) {
        final compiled = entry.value.compile();
        expect(compiled, isNotEmpty, reason: '${entry.key} compiled to no instructions');
      }
    });

    test('every compiled instruction has intensity/sharpness within 0.0-1.0', () {
      for (final entry in HapticPatterns.all.entries) {
        for (final instruction in entry.value.compile()) {
          expect(
            instruction.intensity,
            inInclusiveRange(0.0, 1.0),
            reason: '${entry.key} has an out-of-range intensity',
          );
          expect(
            instruction.sharpness,
            inInclusiveRange(0.0, 1.0),
            reason: '${entry.key} has an out-of-range sharpness',
          );
        }
      }
    });

    test('every compiled instruction has non-negative timing', () {
      for (final entry in HapticPatterns.all.entries) {
        for (final instruction in entry.value.compile()) {
          expect(instruction.durationMs, greaterThanOrEqualTo(0), reason: entry.key);
          expect(instruction.delayMs, greaterThanOrEqualTo(0), reason: entry.key);
        }
      }
    });

    test('every preset is playable via HapticPlayer', () async {
      final platform = _RecordingPlatform();
      HapticPatternsPlatform.instance = platform;

      for (final entry in HapticPatterns.all.entries) {
        platform.lastPlayed = null;
        await entry.value.play();
        expect(platform.lastPlayed, isNotNull, reason: '${entry.key} did not reach the platform');
      }
    });
  });

  group('individual presets', () {
    test('selection is a single light, sharp tap', () {
      final compiled = HapticPatterns.selection.compile();
      expect(compiled, hasLength(1));
      expect(compiled[0].intensity, lessThan(0.5));
      expect(compiled[0].sharpness, greaterThan(0.5));
    });

    test('tick is a single instruction', () {
      expect(HapticPatterns.tick.compile(), hasLength(1));
    });

    test('heavyClick is stronger than softTap', () {
      final heavy = HapticPatterns.heavyClick.compile().single;
      final soft = HapticPatterns.softTap.compile().single;
      expect(heavy.intensity, greaterThan(soft.intensity));
    });

    test('success compiles to two instructions with a gap between them', () {
      final compiled = HapticPatterns.success.compile();
      expect(compiled, hasLength(2));
      expect(compiled[0].delayMs, 0);
      expect(compiled[1].delayMs, 80);
    });

    test('error is two buzzes with explicit duration', () {
      final compiled = HapticPatterns.error.compile();
      expect(compiled, hasLength(2));
      for (final instruction in compiled) {
        expect(instruction.durationMs, 120);
      }
    });

    test('heartbeat has a strong beat followed by a softer one', () {
      final compiled = HapticPatterns.heartbeat.compile();
      expect(compiled, hasLength(2));
      expect(compiled[0].intensity, greaterThan(compiled[1].intensity));
    });

    test('rampUp intensity strictly increases', () {
      final compiled = HapticPatterns.rampUp.compile();
      expect(compiled, hasLength(3));
      expect(compiled[0].intensity, lessThan(compiled[1].intensity));
      expect(compiled[1].intensity, lessThan(compiled[2].intensity));
    });

    test('rampDown intensity strictly decreases', () {
      final compiled = HapticPatterns.rampDown.compile();
      expect(compiled, hasLength(3));
      expect(compiled[0].intensity, greaterThan(compiled[1].intensity));
      expect(compiled[1].intensity, greaterThan(compiled[2].intensity));
    });

    test('drumRoll has five rapid taps', () {
      final compiled = HapticPatterns.drumRoll.compile();
      expect(compiled, hasLength(5));
      // All gaps except the first should be short (rapid).
      for (final instruction in compiled.skip(1)) {
        expect(instruction.delayMs, lessThanOrEqualTo(40));
      }
    });

    test('knock has three evenly spaced firm taps', () {
      final compiled = HapticPatterns.knock.compile();
      expect(compiled, hasLength(3));
      expect(compiled[1].delayMs, 150);
      expect(compiled[2].delayMs, 150);
    });

    test('celebration ends on a soft note', () {
      final compiled = HapticPatterns.celebration.compile();
      expect(compiled.last.intensity, lessThan(compiled[compiled.length - 2].intensity));
    });

    test('bounce fades out across three echoes', () {
      final compiled = HapticPatterns.bounce.compile();
      expect(compiled, hasLength(3));
      expect(compiled[0].intensity, greaterThan(compiled[1].intensity));
      expect(compiled[1].intensity, greaterThan(compiled[2].intensity));
    });

    test('longBuzz has a longer duration than buzz', () {
      final long = HapticPatterns.longBuzz.compile().single;
      final short = HapticPatterns.buzz.compile().single;
      expect(long.durationMs, greaterThan(short.durationMs));
    });

    test('swoosh is a genuine fading curve, not a fixed 3-segment approximation', () {
      final compiled = HapticPatterns.swoosh.compile();
      expect(compiled.length, greaterThan(3));
      expect(compiled.first.intensity, greaterThan(compiled.last.intensity));
      for (var i = 1; i < compiled.length; i++) {
        expect(compiled[i].intensity, lessThanOrEqualTo(compiled[i - 1].intensity));
      }
    });

    test('pulse is three identical beats spaced evenly apart', () {
      final compiled = HapticPatterns.pulse.compile();
      expect(compiled, hasLength(3));
      expect(compiled[1].delayMs, compiled[2].delayMs);
      expect(compiled[0].intensity, compiled[1].intensity);
      expect(compiled[1].intensity, compiled[2].intensity);
    });
  });
}
