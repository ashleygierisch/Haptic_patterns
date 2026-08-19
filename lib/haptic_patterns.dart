/// Composable haptic feedback patterns for Flutter -- chain, repeat,
/// and compose taps, buzzes, and custom sequences on Android and iOS.
///
/// ```dart
/// import 'package:haptic_patterns/haptic_patterns.dart';
///
/// HapticEvent.tap().play();
///
/// HapticSequence([
///   HapticEvent.tap(),
///   delay(50),
///   HapticEvent.tap(),
/// ]).play();
/// ```
library;

export 'src/haptic_instruction.dart';
export 'src/haptic_pattern.dart';
export 'src/haptic_player.dart';
