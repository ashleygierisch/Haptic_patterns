import 'dart:math';

import 'package:flutter/material.dart';
import 'package:haptic_patterns/haptic_patterns.dart';

/// A minimal "tap the target" game that picks its haptic pattern
/// based on what just happened -- a plain hit, a miss, or a streak of
/// hits worth celebrating -- demonstrating patterns chosen dynamically
/// at runtime rather than wired to a single fixed gesture.
///
/// Hit-testing is done with plain geometry against a single
/// full-area [GestureDetector], rather than putting a second
/// [HapticFeedbackWidget] detector directly on the target: nested
/// gesture detectors in Flutter don't exclude each other, so a
/// detector on the target and a detector behind it would *both* fire
/// on every tap that lands on the target, double-counting it as a hit
/// and a miss at once.
class GameDemoPage extends StatefulWidget {
  const GameDemoPage({super.key});

  @override
  State<GameDemoPage> createState() => _GameDemoPageState();
}

class _GameDemoPageState extends State<GameDemoPage> {
  static const _celebrationStreak = 5;
  static const _targetRadius = 32.0;

  final _random = Random();
  int _score = 0;
  int _streak = 0;
  Alignment _targetAlignment = Alignment.center;

  void _moveTarget() {
    setState(() {
      _targetAlignment = Alignment(
        _random.nextDouble() * 1.6 - 0.8,
        _random.nextDouble() * 1.6 - 0.8,
      );
    });
  }

  Offset _targetCenter(Size areaSize) => Offset(
    (areaSize.width / 2) * (1 + _targetAlignment.x),
    (areaSize.height / 2) * (1 + _targetAlignment.y),
  );

  Future<void> _onTapDown(TapDownDetails details, Size areaSize) async {
    final hit = (details.localPosition - _targetCenter(areaSize)).distance <= _targetRadius;

    if (hit) {
      _streak++;
      setState(() => _score++);
      if (_streak % _celebrationStreak == 0) {
        await HapticPatterns.celebration.play();
      } else {
        await HapticPatterns.success.play();
      }
      _moveTarget();
    } else {
      setState(() => _streak = 0);
      await HapticPatterns.error.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(label: 'Score', value: '$_score'),
              _Stat(label: 'Streak', value: '$_streak'),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final areaSize = constraints.biggest;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _onTapDown(details, areaSize),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(color: Theme.of(context).colorScheme.surfaceContainerLow),
                    ),
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      alignment: _targetAlignment,
                      child: IgnorePointer(
                        // Purely decorative -- the GestureDetector above
                        // handles all hit-testing via geometry, so this
                        // must never intercept pointer events itself.
                        child: Container(
                          width: _targetRadius * 2,
                          height: _targetRadius * 2,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.adjust, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
