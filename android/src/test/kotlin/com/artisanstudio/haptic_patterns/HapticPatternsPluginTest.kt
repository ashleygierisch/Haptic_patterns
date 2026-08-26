package com.artisanstudio.haptic_patterns

import android.os.VibrationEffect
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * A plain hand-rolled fake rather than a Mockito mock of the real
 * [android.os.Vibrator] -- that class is final, and the
 * mockable-android-jar stub Android Gradle Plugin substitutes for it
 * in JVM unit tests can't be instrumented by Mockito's inline mock
 * maker under Java 21 (a ByteBuddy/JDK interaction issue). Faking the
 * [HapticVibrator] interface this plugin depends on instead sidesteps
 * that entirely -- see [HapticVibrator]'s doc comment.
 */
private class FakeHapticVibrator : HapticVibrator {
    var hasVibratorResult = true
    var cancelCalled = false
    var lastEffect: VibrationEffect? = null
    var lastLegacyTimings: LongArray? = null
    var lastLegacyRepeat: Int? = null

    override fun hasVibrator(): Boolean = hasVibratorResult

    override fun cancel() {
        cancelCalled = true
    }

    override fun vibrate(effect: VibrationEffect) {
        lastEffect = effect
    }

    override fun vibrateLegacy(
        timings: LongArray,
        repeat: Int,
    ) {
        lastLegacyTimings = timings
        lastLegacyRepeat = repeat
    }
}

internal class HapticPatternsPluginTest {
    private lateinit var fakeVibrator: FakeHapticVibrator
    private lateinit var plugin: HapticPatternsPlugin

    @BeforeTest
    fun setUp() {
        fakeVibrator = FakeHapticVibrator()
        plugin = HapticPatternsPlugin()
        plugin.vibrator = fakeVibrator
    }

    @Test
    fun onMethodCall_unknownMethod_callsNotImplemented() {
        val call = MethodCall("bogus", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).notImplemented()
    }

    @Test
    fun onMethodCall_playInstructions_withNonListArguments_returnsError() {
        val call = MethodCall("playInstructions", "not a list")
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).error(
            Mockito.eq("INVALID_ARGUMENTS"),
            Mockito.anyString(),
            Mockito.isNull(),
        )
    }

    @Test
    fun onMethodCall_stop_cancelsTheVibrator() {
        val call = MethodCall("stop", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        assertTrue(fakeVibrator.cancelCalled)
        Mockito.verify(mockResult).success(null)
    }

    @Test
    fun onMethodCall_isSupported_reflectsHasVibrator() {
        fakeVibrator.hasVibratorResult = true
        val call = MethodCall("isSupported", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success(true)
    }

    @Test
    fun onMethodCall_isSupported_falseWhenDeviceHasNoVibrator() {
        fakeVibrator.hasVibratorResult = false
        val call = MethodCall("isSupported", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success(false)
    }

    @Test
    fun onMethodCall_playInstructions_completesGracefullyWhenDeviceHasNoVibrator() {
        fakeVibrator.hasVibratorResult = false
        val instructions = listOf(mapOf("intensity" to 1.0, "durationMs" to 0L, "delayMs" to 0L))
        val call = MethodCall("playInstructions", instructions)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        assertEquals(null, fakeVibrator.lastEffect)
        assertFalse(fakeVibrator.cancelCalled)
        Mockito.verify(mockResult).success(null)
    }

    // A genuine android.os.VibrationEffect instance can't be produced
    // in a plain JVM unit test: VibrationEffect() is package-private
    // (blocks direct subclassing), Mockito can't mock it (the same
    // "Could not modify all classes" ByteBuddy/JDK21 failure as
    // android.os.Vibrator -- see FakeHapticVibrator's doc comment,
    // and forcing Mockito's classic subclass mock maker for just this
    // mock corrupts every other Mockito.mock() call in the same JVM,
    // which is worse), and even Objenesis's raw-allocation bypass
    // throws InstantiationError since it's abstract -- the JVM itself
    // refuses to allocate an instance of an abstract class regardless
    // of how the constructor is sidestepped. Closing that specific gap
    // needs an instrumented/on-device test, not a JVM unit test (see
    // Day 12 of the project plan). What's provable here instead: the
    // plugin passes the right instructions to vibrationEffectBuilder
    // when the API level warrants it, and correctly no-ops when the
    // builder finds nothing playable.
    @Test
    fun onMethodCall_playInstructions_onApi26OrAbove_invokesVibrationEffectBuilder() {
        plugin.sdkInt = 26 // Build.VERSION_CODES.O, the lower boundary for this branch
        var builtFrom: List<*>? = null
        plugin.vibrationEffectBuilder = { instructions ->
            builtFrom = instructions
            null
        }
        val instructions = listOf(mapOf("intensity" to 1.0, "durationMs" to 100L, "delayMs" to 0L))
        val call = MethodCall("playInstructions", instructions)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        assertEquals(instructions, builtFrom)
        assertEquals(null, fakeVibrator.lastLegacyTimings)
        Mockito.verify(mockResult).success(null)
    }

    @Test
    fun onMethodCall_playInstructions_onApi26OrAbove_withNoPlayableInstructions_doesNotVibrate() {
        plugin.sdkInt = 26
        plugin.vibrationEffectBuilder = { null }
        val instructions = listOf(mapOf("intensity" to 1.0, "durationMs" to 100L, "delayMs" to 0L))
        val call = MethodCall("playInstructions", instructions)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        assertEquals(null, fakeVibrator.lastEffect)
        Mockito.verify(mockResult).success(null)
    }

    @Test
    fun onMethodCall_playInstructions_belowApi26_usesLegacyVibrate() {
        plugin.sdkInt = 25 // one below Build.VERSION_CODES.O, predates VibrationEffect entirely
        val instructions = listOf(mapOf("intensity" to 1.0, "durationMs" to 100L, "delayMs" to 0L))
        val call = MethodCall("playInstructions", instructions)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        assertEquals(null, fakeVibrator.lastEffect)
        assertTrue(fakeVibrator.lastLegacyTimings != null, "expected vibrateLegacy() to be called")
        assertEquals(-1, fakeVibrator.lastLegacyRepeat)
        Mockito.verify(mockResult).success(null)
    }

    @Test
    fun onMethodCall_playInstructions_belowApi26_withEmptyList_doesNotVibrate() {
        plugin.sdkInt = 25
        val call = MethodCall("playInstructions", emptyList<Any>())
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        assertEquals(null, fakeVibrator.lastLegacyTimings)
        Mockito.verify(mockResult).success(null)
    }

    @Test
    fun onMethodCall_playInstructions_withEmptyList_stillSucceeds() {
        val call = MethodCall("playInstructions", emptyList<Any>())
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        assertEquals(null, fakeVibrator.lastEffect)
        Mockito.verify(mockResult).success(null)
    }
}
