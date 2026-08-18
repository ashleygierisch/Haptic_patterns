# haptic_patterns

Composable haptic feedback patterns for Flutter — chain, repeat, and
compose taps, buzzes, and custom sequences on Android and iOS.

[![CI](https://github.com/modexanderson/haptic_patterns/actions/workflows/ci.yml/badge.svg)](https://github.com/modexanderson/haptic_patterns/actions)
[![pub package](https://img.shields.io/pub/v/haptic_patterns.svg)](https://pub.dev/packages/haptic_patterns)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## What it does

```dart
HapticPlayer.play(HapticPatterns.success);

HapticSequence([tick, delay(50), tick, delay(50), tick]).play();
```

Maps composable pattern definitions onto each platform's native haptic
engine — Android `VibrationEffect` compositions, iOS `CHHapticEngine`
— so you describe *what* the feedback should feel like once and it
renders correctly on both platforms.

> **Status:** early scaffold. The public API and platform
> implementations aren't built yet — see the roadmap below.

## Installation

```bash
flutter pub add haptic_patterns
```

## Roadmap

- [x] Plugin scaffold (Android + iOS platform folders, CI)
- [ ] `HapticPattern` / `HapticSequence` / `HapticPlayer` API
- [ ] Android platform channel (`VibrationEffect` compositions)
- [ ] iOS platform channel (`CHHapticEngine` patterns)
- [ ] Preset library (`success`, `error`, `warning`, `heartbeat`, `notification`, `tick`, ...)
- [ ] Pattern composer (chain, repeat, delay, intensity curves)
- [ ] `HapticFeedbackWidget` for tap/long-press/gesture triggers
- [ ] Desktop fallback for development/testing

## Development

```bash
git clone https://github.com/modexanderson/haptic_patterns.git
cd haptic_patterns
flutter pub get
flutter test
```

## License

MIT License — see [LICENSE](LICENSE) for details.
