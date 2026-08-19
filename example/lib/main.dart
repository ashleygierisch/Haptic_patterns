import 'package:flutter/material.dart';
import 'package:haptic_patterns/haptic_patterns.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Minimal placeholder until the native platform implementations land
  // (Days 3-4) and the full example app is built out (Day 10) --
  // a proper pattern playground, not just a single button.
  Future<void> _playTap() => HapticEvent.tap().play();

  Future<void> _playPattern() => HapticSequence([
    HapticEvent.tap(),
    delay(50),
    HapticEvent.tap(),
    delay(50),
    HapticEvent.thud(),
  ]).play();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('haptic_patterns example')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(onPressed: _playTap, child: const Text('Play tap')),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _playPattern, child: const Text('Play pattern')),
            ],
          ),
        ),
      ),
    );
  }
}
