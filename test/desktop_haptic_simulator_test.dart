import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_patterns/haptic_patterns.dart';

class _RecordedBeep {
  _RecordedBeep(this.frequencyHz, this.durationMs);

  final int frequencyHz;
  final int durationMs;
}

void main() {
  group('DesktopHapticSimulator', () {
    test('isSupported is always true', () async {
      final simulator = DesktopHapticSimulator(beep: (_, _) async {});
      expect(await simulator.isSupported(), isTrue);
    });

    test('does nothing for an empty instruction list', () async {
      final calls = <_RecordedBeep>[];
      final simulator = DesktopHapticSimulator(
        beep: (freq, dur) async => calls.add(_RecordedBeep(freq, dur)),
      );

      await simulator.playInstructions(const []);

      expect(calls, isEmpty);
    });

    test('beeps once per instruction, in order', () async {
      final calls = <_RecordedBeep>[];
      final simulator = DesktopHapticSimulator(
        beep: (freq, dur) async => calls.add(_RecordedBeep(freq, dur)),
      );

      await simulator.playInstructions(const [
        HapticInstruction(intensity: 1.0, sharpness: 1.0, durationMs: 0, delayMs: 0),
        HapticInstruction(intensity: 0.5, sharpness: 0.0, durationMs: 100, delayMs: 20),
      ]);

      expect(calls, hasLength(2));
    });

    test('higher sharpness produces a higher-pitched beep', () async {
      final calls = <_RecordedBeep>[];
      final simulator = DesktopHapticSimulator(
        beep: (freq, dur) async => calls.add(_RecordedBeep(freq, dur)),
      );

      await simulator.playInstructions(const [
        HapticInstruction(intensity: 0.5, sharpness: 0.0, durationMs: 0, delayMs: 0),
        HapticInstruction(intensity: 0.5, sharpness: 1.0, durationMs: 0, delayMs: 0),
      ]);

      expect(calls[1].frequencyHz, greaterThan(calls[0].frequencyHz));
    });

    test('higher intensity produces a longer beep', () async {
      final calls = <_RecordedBeep>[];
      final simulator = DesktopHapticSimulator(
        beep: (freq, dur) async => calls.add(_RecordedBeep(freq, dur)),
      );

      await simulator.playInstructions(const [
        HapticInstruction(intensity: 0.1, sharpness: 0.5, durationMs: 200, delayMs: 0),
        HapticInstruction(intensity: 1.0, sharpness: 0.5, durationMs: 200, delayMs: 0),
      ]);

      expect(calls[1].durationMs, greaterThan(calls[0].durationMs));
    });

    test('a transient instruction (durationMs 0) still produces an audible beep length', () async {
      final calls = <_RecordedBeep>[];
      final simulator = DesktopHapticSimulator(
        beep: (freq, dur) async => calls.add(_RecordedBeep(freq, dur)),
      );

      await simulator.playInstructions(const [
        HapticInstruction(intensity: 1.0, sharpness: 1.0, durationMs: 0, delayMs: 0),
      ]);

      expect(calls.single.durationMs, greaterThanOrEqualTo(30));
    });

    test('honors delayMs before each instruction', () async {
      final calls = <_RecordedBeep>[];
      final simulator = DesktopHapticSimulator(
        beep: (freq, dur) async => calls.add(_RecordedBeep(freq, dur)),
      );

      final stopwatch = Stopwatch()..start();
      await simulator.playInstructions(const [
        HapticInstruction(intensity: 0.5, sharpness: 0.5, durationMs: 0, delayMs: 0),
        HapticInstruction(intensity: 0.5, sharpness: 0.5, durationMs: 0, delayMs: 150),
      ]);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(140));
    });

    test('stop() cancels an in-flight sequence before later instructions play', () async {
      final calls = <_RecordedBeep>[];
      final simulator = DesktopHapticSimulator(
        beep: (freq, dur) async => calls.add(_RecordedBeep(freq, dur)),
      );

      final playFuture = simulator.playInstructions(const [
        HapticInstruction(intensity: 0.5, sharpness: 0.5, durationMs: 0, delayMs: 200),
        HapticInstruction(intensity: 0.5, sharpness: 0.5, durationMs: 0, delayMs: 200),
        HapticInstruction(intensity: 0.5, sharpness: 0.5, durationMs: 0, delayMs: 200),
      ]);

      // Let the first delay start, then cancel before it (or anything
      // after it) has a chance to beep.
      await Future.delayed(const Duration(milliseconds: 50));
      await simulator.stop();
      await playFuture;

      expect(calls, isEmpty);
    });

    test('the real (non-injected) beep never throws, even headless', () async {
      // Exercises the actual OS-detection branch in _defaultBeep --
      // every branch is wrapped in its own try/catch specifically so a
      // missing beep utility (e.g. a CI runner with no audio device)
      // can never surface as a crash.
      final simulator = DesktopHapticSimulator();

      await expectLater(
        simulator.playInstructions(const [
          HapticInstruction(intensity: 0.5, sharpness: 0.5, durationMs: 30, delayMs: 0),
        ]),
        completes,
      );
    });

    test('a new playInstructions call after stop() is unaffected', () async {
      final calls = <_RecordedBeep>[];
      final simulator = DesktopHapticSimulator(
        beep: (freq, dur) async => calls.add(_RecordedBeep(freq, dur)),
      );

      await simulator.stop();
      await simulator.playInstructions(const [
        HapticInstruction(intensity: 0.5, sharpness: 0.5, durationMs: 0, delayMs: 0),
      ]);

      expect(calls, hasLength(1));
    });
  });
}
