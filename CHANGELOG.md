## 1.0.0 / Initial release.

- `HapticPattern` DSL: `HapticEvent` (with `.tap()`, `.thud()`, `.buzz()` shapes), `HapticDelay`/`delay()`, `HapticSequence`, `HapticRepeat`, `HapticCurve`
- `HapticPlayer` — `play()`, `stop()`, `isSupported()`
- Android platform channel (`VibrationEffect` compositions, API 24+)
- iOS platform channel (`CHHapticEngine` patterns, with a graceful no-op on hardware that doesn't support haptics)
- Preset library: 25 ready-to-use `HapticPatterns` covering system feedback, rhythmic, sustained, dynamic, and expressive feel
- `HapticFeedbackWidget` for declarative tap/long-press/double-tap-triggered feedback
- `DesktopHapticSimulator` — opt-in audio-based haptic simulation for developing on Windows/macOS/Linux
- Example app: on-screen keyboard, pattern playground, and a tap-the-target game demo
- CI: Dart analyze/test, Android native unit tests, iOS XCTest suite, all across both the plugin and the example app
