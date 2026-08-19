import 'haptic_instruction.dart';
import 'haptic_player.dart';

/// Base type for anything that can be played as haptic feedback -- a
/// single event, a delay, or a composed sequence of patterns.
///
/// Compose patterns freely:
///
/// ```dart
/// HapticSequence([
///   HapticEvent.tap(),
///   delay(50),
///   HapticEvent.tap(),
/// ]).play();
/// ```
sealed class HapticPattern {
  const HapticPattern();

  /// Flattens this pattern (and any nested patterns) into a linear
  /// list of low-level instructions ready for the platform channel.
  List<HapticInstruction> compile();

  /// Plays this pattern via [HapticPlayer.play].
  Future<void> play() => HapticPlayer.play(this);
}

/// A single haptic pulse -- a tap, buzz, or custom impulse.
final class HapticEvent extends HapticPattern {
  /// How strong the pulse feels, from 0.0 (barely perceptible) to 1.0
  /// (full strength).
  final double intensity;

  /// How sharp/crisp the pulse feels, from 0.0 (soft, round) to 1.0
  /// (sharp, crisp).
  final double sharpness;

  /// How long the pulse sustains. [Duration.zero] produces a transient
  /// (instantaneous) tap; anything longer produces a continuous buzz.
  final Duration duration;

  const HapticEvent({
    this.intensity = 1.0,
    this.sharpness = 0.5,
    this.duration = Duration.zero,
  })  : assert(intensity >= 0.0 && intensity <= 1.0, 'intensity must be 0.0-1.0'),
        assert(sharpness >= 0.0 && sharpness <= 1.0, 'sharpness must be 0.0-1.0');

  /// A quick, light tap.
  const HapticEvent.tap({double intensity = 0.6, double sharpness = 0.7})
      : this(intensity: intensity, sharpness: sharpness);

  /// A stronger, blunter thud.
  const HapticEvent.thud({double intensity = 1.0, double sharpness = 0.2})
      : this(intensity: intensity, sharpness: sharpness);

  /// A sustained buzz.
  const HapticEvent.buzz({
    double intensity = 0.8,
    double sharpness = 0.4,
    Duration duration = const Duration(milliseconds: 200),
  }) : this(intensity: intensity, sharpness: sharpness, duration: duration);

  @override
  List<HapticInstruction> compile() => [
        HapticInstruction(
          intensity: intensity,
          sharpness: sharpness,
          durationMs: duration.inMilliseconds,
          delayMs: 0,
        ),
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HapticEvent &&
          intensity == other.intensity &&
          sharpness == other.sharpness &&
          duration == other.duration;

  @override
  int get hashCode => Object.hash(intensity, sharpness, duration);

  @override
  String toString() =>
      'HapticEvent(intensity: $intensity, sharpness: $sharpness, duration: $duration)';
}

/// A pause with no haptic output, used between events in a sequence.
///
/// A [HapticDelay] outside of a [HapticSequence] compiles to nothing
/// playable on its own -- it only has meaning as a gap between the
/// events around it.
final class HapticDelay extends HapticPattern {
  final Duration duration;

  // Note: unlike HapticEvent's intensity/sharpness, there's no assert
  // here rejecting a negative duration -- Duration has no const-
  // evaluable comparison operator or accessor, so that check can't be
  // expressed in a way that keeps this constructor const. A negative
  // delay is a caller error that just produces odd (but harmless)
  // timing, not a crash.
  const HapticDelay(this.duration);

  @override
  List<HapticInstruction> compile() => const [];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HapticDelay && duration == other.duration;

  @override
  int get hashCode => duration.hashCode;

  @override
  String toString() => 'HapticDelay($duration)';
}

/// Shorthand for [HapticDelay] with a millisecond duration, matching
/// the ergonomics of the pattern DSL: `delay(50)`.
HapticDelay delay(int milliseconds) => HapticDelay(Duration(milliseconds: milliseconds));

/// A list of [HapticPattern]s played in order.
///
/// [HapticDelay]s inside the list contribute a gap before whichever
/// instruction follows them, rather than an instruction of their own
/// -- so `HapticSequence([tap, delay(50), tap])` plays two taps 50ms
/// apart, not three events. Sequences nest freely, since a
/// [HapticSequence] is itself a [HapticPattern].
final class HapticSequence extends HapticPattern {
  final List<HapticPattern> patterns;

  const HapticSequence(this.patterns);

  @override
  List<HapticInstruction> compile() {
    final result = <HapticInstruction>[];
    var pendingDelayMs = 0;

    for (final pattern in patterns) {
      if (pattern is HapticDelay) {
        pendingDelayMs += pattern.duration.inMilliseconds;
        continue;
      }

      final compiled = pattern.compile();
      for (var i = 0; i < compiled.length; i++) {
        final instruction = compiled[i];
        final extraDelay = i == 0 ? pendingDelayMs : 0;
        result.add(
          HapticInstruction(
            intensity: instruction.intensity,
            sharpness: instruction.sharpness,
            durationMs: instruction.durationMs,
            delayMs: instruction.delayMs + extraDelay,
          ),
        );
      }
      pendingDelayMs = 0;
    }

    return result;
  }

  @override
  String toString() => 'HapticSequence($patterns)';
}
