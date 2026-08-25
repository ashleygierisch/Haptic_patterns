import 'dart:io';

import 'package:flutter/foundation.dart';

import '../haptic_patterns_platform_interface.dart';
import 'haptic_instruction.dart';

/// Simulates haptic feedback with audible beeps, for developing and
/// testing patterns on a desktop machine that has no vibration
/// hardware.
///
/// This is opt-in -- it is never selected automatically, because
/// `flutter test` and other host-side tooling also run as a desktop
/// process, and a plugin that started beeping during test runs would
/// be a worse experience than one that silently no-ops. Wire it up
/// explicitly for desktop targets in `main()`:
///
/// ```dart
/// void main() {
///   if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
///     HapticPatternsPlatform.instance = DesktopHapticSimulator();
///   }
///   runApp(MyApp());
/// }
/// ```
///
/// [HapticInstruction.sharpness] is mapped to pitch (sharper feels
/// higher-pitched) and [HapticInstruction.intensity] scales the beep's
/// duration, so distinct patterns still sound distinct from each
/// other. This is a rough approximation for development feedback, not
/// a faithful audio reproduction of the pattern.
///
/// Beep support depends on what the host OS has available: Windows
/// uses `Console.Beep` via PowerShell (always present), macOS plays a
/// system alert sound via `afplay` (always present), and Linux tries
/// `paplay` against a freedesktop sound-theme file (present on most
/// PulseAudio/PipeWire desktops, but not guaranteed). Any failure --
/// missing tool, muted output, headless environment -- is swallowed
/// silently, since this is a best-effort developer convenience and
/// must never crash the app it's embedded in.
class DesktopHapticSimulator extends HapticPatternsPlatform {
  /// Creates a simulator. [beep] is exposed for tests that want to
  /// record calls instead of spawning a real OS process; real callers
  /// should leave it unset.
  DesktopHapticSimulator({
    @visibleForTesting Future<void> Function(int frequencyHz, int durationMs)? beep,
  }) : _beep = beep ?? _defaultBeep;

  final Future<void> Function(int frequencyHz, int durationMs) _beep;

  int _generation = 0;

  @override
  Future<void> playInstructions(List<HapticInstruction> instructions) async {
    final generation = ++_generation;

    for (final instruction in instructions) {
      if (instruction.delayMs > 0) {
        await Future.delayed(Duration(milliseconds: instruction.delayMs));
      }
      if (generation != _generation) return;

      await _beep(_frequencyFor(instruction), _durationFor(instruction));
      if (generation != _generation) return;
    }
  }

  @override
  Future<void> stop() async {
    // Bumping the generation makes any in-flight playInstructions loop
    // bail out at its next checkpoint instead of playing further beeps.
    _generation++;
  }

  @override
  Future<bool> isSupported() async => true;

  static int _frequencyFor(HapticInstruction instruction) {
    const minHz = 220;
    const maxHz = 1980;
    return (minHz + instruction.sharpness.clamp(0.0, 1.0) * (maxHz - minHz)).round();
  }

  static int _durationFor(HapticInstruction instruction) {
    final baseMs = instruction.durationMs > 0 ? instruction.durationMs : 60;
    final scaled = baseMs * (0.4 + instruction.intensity.clamp(0.0, 1.0) * 0.6);
    return scaled.round().clamp(30, 1000);
  }

  static Future<void> _defaultBeep(int frequencyHz, int durationMs) async {
    try {
      if (Platform.isWindows) {
        await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          '[console]::beep($frequencyHz,$durationMs)',
        ]);
      } else if (Platform.isMacOS) {
        await Process.run('afplay', ['/System/Library/Sounds/Tink.aiff']);
      } else if (Platform.isLinux) {
        await Process.run('paplay', [
          '/usr/share/sounds/freedesktop/stereo/audio-volume-change.oga',
        ]);
      } else {
        stdout.write('');
      }
    } catch (_) {
      // Best-effort only -- a missing beep utility shouldn't crash the app.
    }
  }
}
