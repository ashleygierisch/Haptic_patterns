import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_patterns/haptic_patterns.dart';
import 'package:haptic_patterns/haptic_patterns_platform_interface.dart';
import 'package:haptic_patterns/haptic_patterns_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockHapticPatternsPlatform
    with MockPlatformInterfaceMixin
    implements HapticPatternsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final HapticPatternsPlatform initialPlatform = HapticPatternsPlatform.instance;

  test('$MethodChannelHapticPatterns is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelHapticPatterns>());
  });

  test('getPlatformVersion', () async {
    HapticPatterns hapticPatternsPlugin = HapticPatterns();
    MockHapticPatternsPlatform fakePlatform = MockHapticPatternsPlatform();
    HapticPatternsPlatform.instance = fakePlatform;

    expect(await hapticPatternsPlugin.getPlatformVersion(), '42');
  });
}
