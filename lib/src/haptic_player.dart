import '../haptic_patterns_platform_interface.dart';
import 'haptic_pattern.dart';

/// Entry point for actually playing a [HapticPattern] on the device.
///
/// ```dart
/// await HapticPlayer.play(HapticEvent.tap());
/// ```
///
/// Most callers will use [HapticPattern.play] instead, which delegates
/// here -- `HapticEvent.tap().play()` reads more naturally than
/// `HapticPlayer.play(HapticEvent.tap())`. `HapticPlayer` itself is
/// useful when you already have a compiled pattern reference you want
/// to reuse, or want direct access to [stop] / [isSupported].
class HapticPlayer {
  const HapticPlayer._();

  /// Compiles and plays [pattern] on the current platform.
  ///
  /// A pattern that compiles to no instructions (an empty
  /// [HapticSequence], or a bare [HapticDelay]) is a no-op.
  static Future<void> play(HapticPattern pattern) {
    final instructions = pattern.compile();
    if (instructions.isEmpty) return Future.value();
    return HapticPatternsPlatform.instance.playInstructions(instructions);
  }

  /// Stops any haptic feedback currently playing.
  static Future<void> stop() => HapticPatternsPlatform.instance.stop();

  /// Whether the current device supports haptic feedback at all.
  ///
  /// Useful to check before playing a pattern that only matters as
  /// feedback (rather than gating functionality on it) -- e.g. to
  /// decide whether to also show a visual cue as a fallback.
  static Future<bool> isSupported() => HapticPatternsPlatform.instance.isSupported();
}
