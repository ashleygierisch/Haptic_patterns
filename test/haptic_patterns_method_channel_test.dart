import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_patterns/haptic_patterns.dart';
import 'package:haptic_patterns/haptic_patterns_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelHapticPatterns();
  const channel = MethodChannel('haptic_patterns');

  final calls = <MethodCall>[];
  dynamic Function(MethodCall)? handlerResponse;

  setUp(() {
    calls.clear();
    handlerResponse = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        calls.add(methodCall);
        return handlerResponse?.call(methodCall);
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  test('playInstructions invokes the channel with a serialized instruction', () async {
    const instruction = HapticInstruction(
      intensity: 0.5,
      sharpness: 0.7,
      durationMs: 100,
      delayMs: 20,
    );

    await platform.playInstructions([instruction]);

    expect(calls, hasLength(1));
    expect(calls.single.method, 'playInstructions');
    expect(calls.single.arguments, [instruction.toMap()]);
  });

  test('playInstructions with multiple instructions preserves order', () async {
    const a = HapticInstruction(intensity: 1, sharpness: 1, durationMs: 0, delayMs: 0);
    const b = HapticInstruction(intensity: 0.5, sharpness: 0.5, durationMs: 10, delayMs: 50);

    await platform.playInstructions([a, b]);

    expect(calls.single.arguments, [a.toMap(), b.toMap()]);
  });

  test('stop invokes the channel', () async {
    await platform.stop();
    expect(calls.single.method, 'stop');
  });

  test('isSupported returns the platform response', () async {
    handlerResponse = (_) => true;
    expect(await platform.isSupported(), isTrue);
    expect(calls.single.method, 'isSupported');
  });

  test('isSupported defaults to false when platform returns null', () async {
    handlerResponse = (_) => null;
    expect(await platform.isSupported(), isFalse);
  });
}
