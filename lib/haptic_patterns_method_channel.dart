import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'haptic_patterns_platform_interface.dart';
import 'src/haptic_instruction.dart';

/// An implementation of [HapticPatternsPlatform] that uses method
/// channels to talk to the native Android/iOS haptic engines.
///
/// The native side of these calls (Kotlin/Swift) isn't implemented
/// yet -- this wires up the Dart-side contract so the API is usable
/// and testable ahead of the platform implementations landing.
class MethodChannelHapticPatterns extends HapticPatternsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('haptic_patterns');

  @override
  Future<void> playInstructions(List<HapticInstruction> instructions) async {
    await methodChannel.invokeMethod<void>(
      'playInstructions',
      instructions.map((instruction) => instruction.toMap()).toList(),
    );
  }

  @override
  Future<void> stop() async {
    await methodChannel.invokeMethod<void>('stop');
  }

  @override
  Future<bool> isSupported() async {
    final supported = await methodChannel.invokeMethod<bool>('isSupported');
    return supported ?? false;
  }
}
