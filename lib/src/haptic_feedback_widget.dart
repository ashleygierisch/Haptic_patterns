import 'package:flutter/widgets.dart';

import 'haptic_pattern.dart';

/// Wraps [child] with gesture detection that plays a [HapticPattern]
/// when triggered, alongside (not instead of) a normal callback.
///
/// Each gesture is independent: a tap, long-press, or double-tap only
/// gets wired up if it has a pattern, a callback, or both -- so
/// wrapping a widget that should only react to long-presses doesn't
/// also swallow its taps.
///
/// ```dart
/// HapticFeedbackWidget(
///   tapPattern: HapticPatterns.tick,
///   onTap: () => print('tapped'),
///   longPressPattern: HapticPatterns.warning,
///   onLongPress: showDeleteConfirmation,
///   child: MyButton(),
/// )
/// ```
///
/// Uses [GestureDetector] under the hood, so it works the same
/// whether [child] is a Material, Cupertino, or plain widget -- this
/// only imports `package:flutter/widgets.dart`, not Material.
class HapticFeedbackWidget extends StatelessWidget {
  /// Creates a [HapticFeedbackWidget] wrapping [child].
  const HapticFeedbackWidget({
    super.key,
    required this.child,
    this.tapPattern,
    this.onTap,
    this.longPressPattern,
    this.onLongPress,
    this.doubleTapPattern,
    this.onDoubleTap,
    this.behavior,
  });

  /// The widget to wrap with gesture detection.
  final Widget child;

  /// Played when the widget is tapped.
  final HapticPattern? tapPattern;

  /// Called after [tapPattern] starts playing.
  final VoidCallback? onTap;

  /// Played when the widget is long-pressed.
  final HapticPattern? longPressPattern;

  /// Called after [longPressPattern] starts playing.
  final VoidCallback? onLongPress;

  /// Played when the widget is double-tapped.
  final HapticPattern? doubleTapPattern;

  /// Called after [doubleTapPattern] starts playing.
  final VoidCallback? onDoubleTap;

  /// How this widget behaves during hit testing. Forwarded directly to
  /// the underlying [GestureDetector].
  final HitTestBehavior? behavior;

  bool get _hasTap => tapPattern != null || onTap != null;

  bool get _hasLongPress => longPressPattern != null || onLongPress != null;

  bool get _hasDoubleTap => doubleTapPattern != null || onDoubleTap != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: behavior,
      onTap: _hasTap ? () => _trigger(tapPattern, onTap) : null,
      onLongPress: _hasLongPress ? () => _trigger(longPressPattern, onLongPress) : null,
      onDoubleTap: _hasDoubleTap ? () => _trigger(doubleTapPattern, onDoubleTap) : null,
      child: child,
    );
  }

  void _trigger(HapticPattern? pattern, VoidCallback? callback) {
    // Fire-and-forget -- the caller's callback shouldn't have to wait
    // on the platform channel round-trip before running.
    pattern?.play();
    callback?.call();
  }
}
