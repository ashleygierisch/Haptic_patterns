import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'haptic_patterns_method_channel.dart';

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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
