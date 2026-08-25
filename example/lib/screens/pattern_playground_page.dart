import 'package:flutter/material.dart';
import 'package:haptic_patterns/haptic_patterns.dart';

/// Browse every preset in [HapticPatterns.all] and play it on demand,
/// plus build and play a custom [HapticEvent] from live intensity and
/// sharpness sliders -- a hands-on reference for what each parameter
/// actually feels like.
class PatternPlaygroundPage extends StatefulWidget {
  const PatternPlaygroundPage({super.key});

  @override
  State<PatternPlaygroundPage> createState() => _PatternPlaygroundPageState();
}

class _PatternPlaygroundPageState extends State<PatternPlaygroundPage> {
  double _intensity = 0.6;
  double _sharpness = 0.5;

  @override
  Widget build(BuildContext context) {
    final presets = HapticPatterns.all.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Custom event', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _LabeledSlider(
          label: 'Intensity',
          value: _intensity,
          onChanged: (v) => setState(() => _intensity = v),
        ),
        _LabeledSlider(
          label: 'Sharpness',
          value: _sharpness,
          onChanged: (v) => setState(() => _sharpness = v),
        ),
        const SizedBox(height: 8),
        HapticFeedbackWidget(
          tapPattern: HapticEvent(intensity: _intensity, sharpness: _sharpness),
          child: FilledButton(
            onPressed: () {},
            child: const Text('Play custom event'),
          ),
        ),
        const Divider(height: 32),
        Text('Presets', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final entry in presets)
          HapticFeedbackWidget(
            tapPattern: entry.value,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.vibration),
                title: Text(entry.key),
              ),
            ),
          ),
      ],
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({required this.label, required this.value, required this.onChanged});

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: Slider(value: value, onChanged: onChanged, label: value.toStringAsFixed(2)),
        ),
        SizedBox(width: 40, child: Text(value.toStringAsFixed(2))),
      ],
    );
  }
}
