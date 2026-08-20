package com.artisanstudio.haptic_patterns

import android.os.VibrationEffect
import android.os.Vibrator

/**
 * Thin wrapper around the handful of [Vibrator] methods this plugin
 * actually uses.
 *
 * [Vibrator] is a final Android framework class, and the
 * mockable-android-jar stub Android Gradle Plugin substitutes for it
 * in JVM unit tests can't be instrumented by Mockito's inline mock
 * maker (a ByteBuddy/JDK interaction issue, not something under this
 * plugin's control). Testing against this interface instead sidesteps
 * that entirely -- [HapticPatternsPluginTest] implements it directly
 * as a plain fake, no framework-class mocking involved.
 */
interface HapticVibrator {
    fun hasVibrator(): Boolean

    fun cancel()

    fun vibrate(effect: VibrationEffect)

    fun vibrateLegacy(timings: LongArray, repeat: Int)
}

/** The real implementation, delegating to an actual [Vibrator]. */
class SystemHapticVibrator(
    private val vibrator: Vibrator,
) : HapticVibrator {
    override fun hasVibrator(): Boolean = vibrator.hasVibrator()

    override fun cancel() = vibrator.cancel()

    override fun vibrate(effect: VibrationEffect) = vibrator.vibrate(effect)

    @Suppress("DEPRECATION")
    override fun vibrateLegacy(
        timings: LongArray,
        repeat: Int,
    ) = vibrator.vibrate(timings, repeat)
}
