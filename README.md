# haptic_patterns

Composable haptic feedback patterns for Flutter — chain, repeat, and
compose taps, buzzes, and custom sequences on Android and iOS.

[![CI](https://github.com/modexanderson/haptic_patterns/actions/workflows/ci.yml/badge.svg)](https://github.com/modexanderson/haptic_patterns/actions)
[![pub package](https://img.shields.io/pub/v/haptic_patterns.svg)](https://pub.dev/packages/haptic_patterns)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Most haptics plugins give you a single `vibrate()` call. `haptic_patterns`
gives you a small DSL for describing what feedback should actually *feel*
like — a sequence of pulses, a repeated buzz, a fading curve — and maps it
onto each platform's real native haptic engine: Android `VibrationEffect`
compositions and iOS `CHHapticEngine` patterns. Describe the feel once; it
renders correctly on both.

```dart
import 'package:haptic_patterns/haptic_patterns.dart';

// A ready-made preset.
HapticPatterns.success.play();

// Or build your own from scratch.
HapticSequence([
  HapticEvent.tap(),
  delay(50),
  HapticEvent.tap(),
  delay(50),
  HapticEvent.thud(),
]).play();
```

## Installation

```bash
flutter pub add haptic_patterns
```

No further setup needed — Android and iOS both work out of the box.

## Quickstart

```dart
import 'package:haptic_patterns/haptic_patterns.dart';

// Play a single tap.
HapticEvent.tap().play();

// Play one of 25 built-in presets.
HapticPatterns.celebration.play();

// Wrap a widget so a gesture plays a pattern automatically.
HapticFeedbackWidget(
  tapPattern: HapticPatterns.selection,
  onTap: () => setState(() => count++),
  child: MyButton(),
)
```

## The pattern DSL

Every pattern is a `HapticPattern`. They compose freely, since a
composed pattern is itself a `HapticPattern`:

| Type | What it does |
|---|---|
| `HapticEvent` | A single pulse. `.tap()`, `.thud()`, and `.buzz()` are ready-made shapes; the base constructor takes `intensity` (0.0–1.0), `sharpness` (0.0–1.0), and `duration` (`Duration.zero` for a transient tap). |
| `HapticSequence([...])` | Plays a list of patterns in order. Use `delay(ms)` between entries to space them out. |
| `HapticRepeat(pattern, count:, gap:)` | Repeats a pattern `count` times with `gap` between repetitions. |
| `HapticCurve(startIntensity:, endIntensity:, duration:, steps:)` | Approximates a smooth intensity ramp/fade as closely-spaced discrete pulses — the same instruction format works on both platforms without native-only APIs. |
| `HapticDelay` / `delay(ms)` | A pause with no haptic output. Only meaningful inside a `HapticSequence`, as a gap before whatever follows it. |

Every pattern reduces to a flat `List<HapticInstruction>` via
`.compile()`, which is what actually crosses the platform channel —
composing patterns is purely a Dart-side concern; native code never has
to understand `HapticSequence` or `HapticRepeat` as such.

```dart
// Three buzzes, 80ms apart.
HapticRepeat(HapticEvent.buzz(), count: 3, gap: Duration(milliseconds: 80));

// A fade-out over 200ms.
HapticCurve(startIntensity: 0.8, endIntensity: 0.0, duration: Duration(milliseconds: 200));
```

## Playing patterns

```dart
await HapticPlayer.play(pattern);   // equivalent to pattern.play()
await HapticPlayer.stop();          // stop whatever's currently playing
await HapticPlayer.isSupported();   // whether the device has haptic hardware
```

`HapticPattern.play()` is shorthand for `HapticPlayer.play(this)` — most
call sites read more naturally as `HapticEvent.tap().play()`. Reach for
`HapticPlayer` directly when you already hold a compiled pattern
reference, or want `.stop()` / `.isSupported()`.

## `HapticFeedbackWidget`

Wraps a child with tap/long-press/double-tap detection that plays a
pattern *alongside* — not instead of — a normal callback:

```dart
HapticFeedbackWidget(
  tapPattern: HapticPatterns.tick,
  onTap: () => print('tapped'),
  longPressPattern: HapticPatterns.warning,
  onLongPress: showDeleteConfirmation,
  child: MyButton(),
)
```

Each gesture wires up independently: a widget with only
`longPressPattern` set doesn't swallow its taps, and one with only a
callback (no pattern) plays nothing but still calls back normally. It
uses `GestureDetector` under the hood, so it works with Material,
Cupertino, or plain widgets — the widget itself only imports
`package:flutter/widgets.dart`.

## Pattern catalog

`HapticPatterns` ships 25 ready-to-use presets. `HapticPatterns.all` is a
`Map<String, HapticPattern>` of all of them, handy for building a picker
UI (see the example app's Playground tab).

**System-feedback-style**

| Preset | Feel |
|---|---|
| `success` | A firm tap followed by a lighter confirming pulse. |
| `error` | An insistent double-buzz. |
| `warning` | A moderate double-tap — needs attention, less severe than `error`. |
| `selection` | A very light, quick tap — scroll detents, picker changes, toggles. |
| `notification` | A distinct three-pulse pattern for incoming alerts. |

**Rhythmic**

| Preset | Feel |
|---|---|
| `heartbeat` | A strong "lub" followed closely by a softer "dub". |
| `tick` | A single minimal tap — clock tick, scroll wheel detent. |
| `doubleTick` | Two quick ticks close together. |
| `heavyClick` | One strong, sharp click — button press, toggle confirm. |
| `softTap` | A gentle, low-intensity tap — a subtle acknowledgement. |

**Sustained**

| Preset | Feel |
|---|---|
| `buzz` | A short sustained buzz. |
| `longBuzz` | A longer sustained buzz — e.g. a long-press acknowledgement. |
| `pulse` | A rhythmic on-off pulse, three beats. |

**Dynamics**

| Preset | Feel |
|---|---|
| `rampUp` | Three taps of increasing intensity — building anticipation. |
| `rampDown` | Three taps of decreasing intensity — winding down. |
| `swoosh` | A smooth buzz that fades toward the end (`HapticCurve`). |

**Expressive**

| Preset | Feel |
|---|---|
| `confirm` | A single crisp confirming tap. |
| `cancel` | A blunt, dismissive single thud. |
| `alert` | A sharp triple-tap for grabbing attention. |
| `celebration` | A playful multi-tap flourish — level up, achievement unlocked. |
| `typewriter` | A very quick, light tick — keystroke feedback for a custom keyboard. |
| `drumRoll` | Four rapid light taps finishing on a slightly stronger accent. |
| `knock` | Three firm taps, like knocking on a door. |
| `pop` | A quick, sharp single pulse, like a bubble popping. |
| `bounce` | Strong, then two lighter echoes fading out. |

## Developing on desktop

Windows/macOS/Linux have no vibration hardware, and `flutter test` runs
as a desktop process too — so `haptic_patterns` never auto-detects the
platform and starts making noise on its own. If you want audible
feedback while developing on desktop, opt in explicitly:

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:haptic_patterns/haptic_patterns.dart';
import 'package:haptic_patterns/haptic_patterns_platform_interface.dart';

void main() {
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    HapticPatternsPlatform.instance = DesktopHapticSimulator();
  }
  runApp(MyApp());
}
```

`DesktopHapticSimulator` plays audible beeps in place of real haptics —
`sharpness` maps to pitch, `intensity` scales duration — so distinct
patterns still sound distinct from each other. It's a rough
approximation for development feedback, not a faithful audio
reproduction.

## Testing your own code

`HapticPatternsPlatform.instance` is swappable, so code that calls
`.play()` is straightforward to test without touching a real device:

```dart
import 'package:haptic_patterns/haptic_patterns.dart';
import 'package:haptic_patterns/haptic_patterns_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeHapticPlatform with MockPlatformInterfaceMixin implements HapticPatternsPlatform {
  List<HapticInstruction>? lastPlayed;

  @override
  Future<void> playInstructions(List<HapticInstruction> instructions) async {
    lastPlayed = instructions;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<bool> isSupported() async => true;
}

// In a test:
HapticPatternsPlatform.instance = FakeHapticPlatform();
```

## Example app

The [example app](example) has three tabs that exercise the whole
public API: an on-screen keyboard bound to `HapticFeedbackWidget`, a
playground that plays every preset plus a custom event built from live
sliders, and a tap-the-target game that picks its pattern from runtime
state.

```bash
cd example
flutter run
```

## Development

```bash
git clone https://github.com/modexanderson/haptic_patterns.git
cd haptic_patterns
flutter pub get
flutter test
```

## License

MIT License — see [LICENSE](LICENSE) for details.
