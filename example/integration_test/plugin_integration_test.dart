// Integration tests run in a full Flutter application on a real
// device/emulator, so they can exercise the actual native platform
// implementations -- unlike the Dart unit tests in test/, which mock
// the platform interface. Not run by CI; meaningful once the Android
// (Day 3) and iOS (Day 4) implementations land.
//
// See https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_patterns/haptic_patterns.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('isSupported reports a real answer from the platform', (tester) async {
    final supported = await HapticPlayer.isSupported();
    expect(supported, isA<bool>());
  });
}
