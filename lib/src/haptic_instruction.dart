/// A single, flattened haptic instruction ready to cross the platform
/// channel.
///
/// [HapticPattern.compile] reduces any composable pattern tree (single
/// events, delays, nested sequences) down to a flat list of these, so
/// native code only ever has to deal with one simple, uniform shape
/// instead of re-implementing Dart's composition logic on both
/// Android and iOS.
class HapticInstruction {
  /// How strong the pulse feels, from 0.0 (barely perceptible) to 1.0
  /// (full strength).
  final double intensity;

  /// How sharp/crisp the pulse feels, from 0.0 (soft, round) to 1.0
  /// (sharp, crisp). Maps directly to iOS's `CHHapticEvent` sharpness
  /// parameter; Android approximates it via amplitude/waveform shaping.
  final double sharpness;

  /// How long the pulse sustains, in milliseconds. 0 produces a
  /// transient (instantaneous) tap; anything longer produces a
  /// continuous buzz.
  final int durationMs;

  /// How long to wait, in milliseconds, before this instruction plays
  /// relative to the one before it.
  final int delayMs;

  const HapticInstruction({
    required this.intensity,
    required this.sharpness,
    required this.durationMs,
    required this.delayMs,
  });

  Map<String, Object> toMap() => {
        'intensity': intensity,
        'sharpness': sharpness,
        'durationMs': durationMs,
        'delayMs': delayMs,
      };

  @override
  String toString() =>
      'HapticInstruction(intensity: $intensity, sharpness: $sharpness, '
      'durationMs: $durationMs, delayMs: $delayMs)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HapticInstruction &&
          intensity == other.intensity &&
          sharpness == other.sharpness &&
          durationMs == other.durationMs &&
          delayMs == other.delayMs;

  @override
  int get hashCode => Object.hash(intensity, sharpness, durationMs, delayMs);
}
