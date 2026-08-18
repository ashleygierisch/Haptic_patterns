
import 'haptic_patterns_platform_interface.dart';

class HapticPatterns {
  Future<String?> getPlatformVersion() {
    return HapticPatternsPlatform.instance.getPlatformVersion();
  }
}
