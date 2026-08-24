import 'haptic_pattern.dart';

/// A curated library of ready-to-use [HapticPattern]s, covering common
/// feedback moments: system-style confirmations, rhythmic taps,
/// sustained buzzes, and a few expressive/playful ones.
///
/// ```dart
/// HapticPatterns.success.play();
/// ```
///
/// Every preset is a [HapticPattern] regardless of whether it's backed
/// by a single [HapticEvent] or a multi-step [HapticSequence] under
/// the hood -- that's an implementation detail, not part of the
/// contract, so it can change without breaking callers.
class HapticPatterns {
  HapticPatterns._();

  // ---------------------------------------------------------------
  // System-feedback-style
  // ---------------------------------------------------------------

  /// A satisfying "task completed" feel: a firm tap followed by a
  /// lighter confirming pulse.
  static final HapticPattern success = HapticSequence([
    const HapticEvent(intensity: 0.8, sharpness: 0.6),
    delay(80),
    const HapticEvent(intensity: 0.5, sharpness: 0.8),
  ]);

  /// An insistent double-buzz for failures and errors.
  static final HapticPattern error = HapticSequence([
    const HapticEvent.buzz(
      intensity: 0.9,
      sharpness: 0.3,
      duration: Duration(milliseconds: 120),
    ),
    delay(60),
    const HapticEvent.buzz(
      intensity: 0.9,
      sharpness: 0.3,
      duration: Duration(milliseconds: 120),
    ),
  ]);

  /// A moderate double-tap -- needs attention, but less severe than
  /// [error].
  static final HapticPattern warning = HapticSequence([
    const HapticEvent(intensity: 0.7, sharpness: 0.5),
    delay(100),
    const HapticEvent(intensity: 0.7, sharpness: 0.5),
  ]);

  /// A very light, quick tap -- scroll detents, picker selection
  /// changes, toggles.
  static const HapticPattern selection = HapticEvent(intensity: 0.3, sharpness: 0.9);

  /// A distinct three-pulse pattern for incoming notifications and
  /// alerts.
  static final HapticPattern notification = HapticSequence([
    const HapticEvent(intensity: 0.6, sharpness: 0.7),
    delay(90),
    const HapticEvent(intensity: 0.6, sharpness: 0.7),
    delay(90),
    const HapticEvent(intensity: 0.8, sharpness: 0.6),
  ]);

  // ---------------------------------------------------------------
  // Rhythmic
  // ---------------------------------------------------------------

  /// One heartbeat cycle -- a strong "lub" followed closely by a
  /// softer "dub".
  static final HapticPattern heartbeat = HapticSequence([
    const HapticEvent(intensity: 0.9, sharpness: 0.3),
    delay(120),
    const HapticEvent(intensity: 0.5, sharpness: 0.3),
  ]);

  /// A single minimal tap -- clock tick, scroll wheel detent.
  static const HapticPattern tick = HapticEvent(intensity: 0.4, sharpness: 0.9);

  /// Two quick ticks close together.
  static final HapticPattern doubleTick = HapticSequence([
    const HapticEvent(intensity: 0.4, sharpness: 0.9),
    delay(60),
    const HapticEvent(intensity: 0.4, sharpness: 0.9),
  ]);

  /// One strong, sharp click -- button press, toggle confirm.
  static const HapticPattern heavyClick = HapticEvent(intensity: 1.0, sharpness: 0.8);

  /// A gentle, low-intensity tap -- a subtle acknowledgement.
  static const HapticPattern softTap = HapticEvent(intensity: 0.2, sharpness: 0.4);

  // ---------------------------------------------------------------
  // Sustained
  // ---------------------------------------------------------------

  /// A short sustained buzz.
  static const HapticPattern buzz = HapticEvent.buzz();

  /// A longer sustained buzz -- e.g. a long-press acknowledgement.
  static const HapticPattern longBuzz = HapticEvent.buzz(
    intensity: 0.7,
    sharpness: 0.3,
    duration: Duration(milliseconds: 500),
  );

  /// A rhythmic on-off pulse, three beats.
  static const HapticPattern pulse = HapticRepeat(
    HapticEvent.buzz(intensity: 0.7, duration: Duration(milliseconds: 80)),
    count: 3,
    gap: Duration(milliseconds: 80),
  );

  // ---------------------------------------------------------------
  // Dynamics
  // ---------------------------------------------------------------

  /// Three taps of increasing intensity -- building anticipation.
  static final HapticPattern rampUp = HapticSequence([
    const HapticEvent(intensity: 0.3, sharpness: 0.6),
    delay(70),
    const HapticEvent(intensity: 0.6, sharpness: 0.6),
    delay(70),
    const HapticEvent(intensity: 1.0, sharpness: 0.6),
  ]);

  /// Three taps of decreasing intensity -- winding down, fading out.
  static final HapticPattern rampDown = HapticSequence([
    const HapticEvent(intensity: 1.0, sharpness: 0.6),
    delay(70),
    const HapticEvent(intensity: 0.6, sharpness: 0.6),
    delay(70),
    const HapticEvent(intensity: 0.3, sharpness: 0.6),
  ]);

  /// A smooth buzz that fades toward the end.
  static const HapticPattern swoosh = HapticCurve(
    startIntensity: 0.8,
    endIntensity: 0.0,
    sharpness: 0.2,
    duration: Duration(milliseconds: 180),
  );

  // ---------------------------------------------------------------
  // Expressive
  // ---------------------------------------------------------------

  /// A single crisp confirming tap.
  static const HapticPattern confirm = HapticEvent(intensity: 0.7, sharpness: 0.7);

  /// A blunt, dismissive single thud.
  static const HapticPattern cancel = HapticEvent.thud(intensity: 0.6);

  /// A sharp triple-tap for grabbing attention.
  static final HapticPattern alert = HapticSequence([
    const HapticEvent(intensity: 0.9, sharpness: 0.8),
    delay(60),
    const HapticEvent(intensity: 0.9, sharpness: 0.8),
    delay(60),
    const HapticEvent(intensity: 0.9, sharpness: 0.8),
  ]);

  /// A playful multi-tap flourish for celebratory moments -- level up,
  /// achievement unlocked.
  static final HapticPattern celebration = HapticSequence([
    const HapticEvent(intensity: 0.6, sharpness: 0.8),
    delay(50),
    const HapticEvent(intensity: 0.8, sharpness: 0.8),
    delay(50),
    const HapticEvent(intensity: 1.0, sharpness: 0.9),
    delay(100),
    const HapticEvent(intensity: 0.5, sharpness: 0.6),
  ]);

  /// A very quick, light tick -- keystroke feedback for a custom
  /// keyboard.
  static const HapticPattern typewriter = HapticEvent(intensity: 0.25, sharpness: 1.0);

  /// Rapid successive light taps, like a drum roll -- four even taps
  /// (via [HapticRepeat]) finishing on one slightly stronger accent.
  static final HapticPattern drumRoll = HapticSequence([
    const HapticRepeat(
      HapticEvent(intensity: 0.5, sharpness: 0.9),
      count: 4,
      gap: Duration(milliseconds: 40),
    ),
    delay(40),
    const HapticEvent(intensity: 0.7, sharpness: 0.9),
  ]);

  /// Three firm taps, like knocking on a door.
  static final HapticPattern knock = HapticSequence([
    const HapticEvent(intensity: 0.8, sharpness: 0.4),
    delay(150),
    const HapticEvent(intensity: 0.8, sharpness: 0.4),
    delay(150),
    const HapticEvent(intensity: 0.8, sharpness: 0.4),
  ]);

  /// A quick, sharp single pulse, like a bubble popping.
  static const HapticPattern pop = HapticEvent(intensity: 0.6, sharpness: 1.0);

  /// A tap that bounces: strong, then two lighter echoes fading out.
  static final HapticPattern bounce = HapticSequence([
    const HapticEvent(intensity: 0.9, sharpness: 0.5),
    delay(90),
    const HapticEvent(intensity: 0.5, sharpness: 0.5),
    delay(70),
    const HapticEvent(intensity: 0.2, sharpness: 0.5),
  ]);

  /// Every preset in the library, keyed by name -- useful for building
  /// a pattern picker/playground UI without hand-maintaining a
  /// separate list in sync with the fields above.
  static final Map<String, HapticPattern> all = {
    'success': success,
    'error': error,
    'warning': warning,
    'selection': selection,
    'notification': notification,
    'heartbeat': heartbeat,
    'tick': tick,
    'doubleTick': doubleTick,
    'heavyClick': heavyClick,
    'softTap': softTap,
    'buzz': buzz,
    'longBuzz': longBuzz,
    'pulse': pulse,
    'rampUp': rampUp,
    'rampDown': rampDown,
    'swoosh': swoosh,
    'confirm': confirm,
    'cancel': cancel,
    'alert': alert,
    'celebration': celebration,
    'typewriter': typewriter,
    'drumRoll': drumRoll,
    'knock': knock,
    'pop': pop,
    'bounce': bounce,
  };
}
