import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_patterns/haptic_patterns_platform_interface.dart';

/// A platform implementation that overrides nothing, standing in for
/// a third-party package that only partially implements the
/// contract. Every method should fall through to the base class's
/// `UnimplementedError`, not silently succeed or crash some other way.
///
/// This genuinely extends [HapticPatternsPlatform] (rather than using
/// `MockPlatformInterfaceMixin`), so it goes through the real
/// constructor and carries the real platform-interface token -- it's
/// accepted by [HapticPatternsPlatform.instance]'s token check the
/// same way any real platform implementation would be.
class _UnimplementedPlatform extends HapticPatternsPlatform {}

void main() {
  group('HapticPatternsPlatform', () {
    final platform = _UnimplementedPlatform();

    test('playInstructions throws UnimplementedError by default', () {
      expect(() => platform.playInstructions(const []), throwsUnimplementedError);
    });

    test('stop throws UnimplementedError by default', () {
      expect(() => platform.stop(), throwsUnimplementedError);
    });

    test('isSupported throws UnimplementedError by default', () {
      expect(() => platform.isSupported(), throwsUnimplementedError);
    });

    test('setting instance verifies the platform interface token', () {
      final original = HapticPatternsPlatform.instance;
      addTearDown(() => HapticPatternsPlatform.instance = original);

      expect(() => HapticPatternsPlatform.instance = platform, returnsNormally);
      expect(HapticPatternsPlatform.instance, same(platform));
    });
  });
}
