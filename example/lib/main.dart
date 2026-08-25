import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:haptic_patterns/haptic_patterns.dart';
import 'package:haptic_patterns/haptic_patterns_platform_interface.dart';

import 'screens/game_demo_page.dart';
import 'screens/keyboard_demo_page.dart';
import 'screens/pattern_playground_page.dart';

void main() {
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    HapticPatternsPlatform.instance = DesktopHapticSimulator();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'haptic_patterns example',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _index = 0;

  static const _pages = [KeyboardDemoPage(), PatternPlaygroundPage(), GameDemoPage()];

  static const _titles = ['Keyboard', 'Playground', 'Game'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.keyboard), label: 'Keyboard'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Playground'),
          NavigationDestination(icon: Icon(Icons.sports_esports), label: 'Game'),
        ],
      ),
    );
  }
}
