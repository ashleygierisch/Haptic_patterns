import 'package:flutter/material.dart';
import 'package:haptic_patterns/haptic_patterns.dart';

/// An on-screen keyboard where every key press has its own haptic
/// feel: a light tick for letters, a firmer tap for space, and a
/// warning buzz for backspace -- demonstrating [HapticFeedbackWidget]
/// wired directly onto a real interactive grid of keys.
class KeyboardDemoPage extends StatefulWidget {
  const KeyboardDemoPage({super.key});

  @override
  State<KeyboardDemoPage> createState() => _KeyboardDemoPageState();
}

class _KeyboardDemoPageState extends State<KeyboardDemoPage> {
  static const _rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];

  final _text = StringBuffer();

  void _type(String char) {
    setState(() => _text.write(char));
  }

  void _backspace() {
    if (_text.isEmpty) return;
    final current = _text.toString();
    setState(() {
      _text.clear();
      _text.write(current.substring(0, current.length - 1));
    });
  }

  void _space() {
    setState(() => _text.write(' '));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _text.isEmpty ? 'Type something…' : _text.toString(),
              key: const Key('typed-text'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 24),
          for (final row in _rows) ...[_KeyRow(letters: row, onKeyTap: _type), const SizedBox(height: 8)],
          Row(
            children: [
              Expanded(
                child: _Key(
                  label: '⌫',
                  pattern: HapticPatterns.warning,
                  onTap: _backspace,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: _Key(label: 'space', pattern: HapticPatterns.tick, onTap: _space),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.letters, required this.onKeyTap});

  final String letters;
  final ValueChanged<String> onKeyTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final letter in letters.split(''))
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _Key(
                label: letter,
                pattern: HapticPatterns.selection,
                onTap: () => onKeyTap(letter),
              ),
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.pattern, required this.onTap});

  final String label;
  final HapticPattern pattern;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HapticFeedbackWidget(
      tapPattern: pattern,
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label),
      ),
    );
  }
}
