import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_patterns/haptic_patterns.dart';
import 'package:haptic_patterns/haptic_patterns_method_channel.dart';
import 'package:haptic_patterns/haptic_patterns_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockHapticPatternsPlatform with MockPlatformInterfaceMixin implements HapticPatternsPlatform {
  List<HapticInstruction>? lastPlayed;
  bool stopped = false;
  bool supported = true;

  @override
  Future<void> playInstructions(List<HapticInstruction> instructions) async {
    lastPlayed = instructions;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<bool> isSupported() async => supported;
}

void main() {
  final HapticPatternsPlatform initialPlatform = HapticPatternsPlatform.instance;

  test('$MethodChannelHapticPatterns is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelHapticPatterns>());
  });

  group('HapticPlayer', () {
    late MockHapticPatternsPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockHapticPatternsPlatform();
      HapticPatternsPlatform.instance = mockPlatform;
    });

    test('play compiles and forwards instructions to the platform', () async {
      await HapticPlayer.play(HapticEvent.tap());
      expect(mockPlatform.lastPlayed, isNotNull);
      expect(mockPlatform.lastPlayed!.length, 1);
    });

    test('play forwards a full compiled sequence', () async {
      await HapticPlayer.play(HapticSequence([HapticEvent.tap(), delay(50), HapticEvent.tap()]));
      expect(mockPlatform.lastPlayed!.length, 2);
      expect(mockPlatform.lastPlayed![1].delayMs, 50);
    });

    test('play is a no-op for an empty sequence', () async {
      await HapticPlayer.play(const HapticSequence([]));
      expect(mockPlatform.lastPlayed, isNull);
    });

    test('play is a no-op for a bare delay', () async {
      await HapticPlayer.play(delay(100));
      expect(mockPlatform.lastPlayed, isNull);
    });

    test('stop delegates to the platform', () async {
      await HapticPlayer.stop();
      expect(mockPlatform.stopped, isTrue);
    });

    test('isSupported delegates to the platform', () async {
      mockPlatform.supported = false;
      expect(await HapticPlayer.isSupported(), isFalse);
    });

    test('HapticPattern.play() delegates to HapticPlayer.play()', () async {
      await HapticEvent.buzz().play();
      expect(mockPlatform.lastPlayed, isNotNull);
    });
  });
}
