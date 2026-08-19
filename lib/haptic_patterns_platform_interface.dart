import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'haptic_patterns_method_channel.dart';
import 'src/haptic_instruction.dart';

/// The interface platform-specific implementations of `haptic_patterns`
/// must implement.
///
/// This is the contract [HapticPlayer] talks to -- it doesn't know or
/// care whether it's backed by a method channel, a mock in tests, or
/// (for third-party platforms) something else entirely.
abstract class HapticPatternsPlatform extends PlatformInterface {
  /// Constructs a HapticPatternsPlatform.
  HapticPatternsPlatform() : super(token: _token);

  static final Object _token = Object();

  static HapticPatternsPlatform _instance = MethodChannelHapticPatterns();

  /// The default instance of [HapticPatternsPlatform] to use.
  ///
  /// Defaults to [MethodChannelHapticPatterns].
  static HapticPatternsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [HapticPatternsPlatform] when
  /// they register themselves.
  static set instance(HapticPatternsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Plays a flattened list of [HapticInstruction]s in order.
  Future<void> playInstructions(List<HapticInstruction> instructions) {
    throw UnimplementedError('playInstructions() has not been implemented.');
  }

  /// Stops any haptic feedback currently playing.
  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  /// Whether the current device supports haptic feedback at all.
  Future<bool> isSupported() {
    throw UnimplementedError('isSupported() has not been implemented.');
  }
}
