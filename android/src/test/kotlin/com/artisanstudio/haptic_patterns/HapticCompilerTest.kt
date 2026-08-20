package com.artisanstudio.haptic_patterns

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class HapticCompilerTest {
    @Test
    fun parseInstruction_readsAllFields() {
        val map = mapOf("intensity" to 0.5, "durationMs" to 100L, "delayMs" to 20L)
        val parsed = HapticCompiler.parseInstruction(map)

        assertEquals(0.5, parsed.intensity)
        assertEquals(100L, parsed.durationMs)
        assertEquals(20L, parsed.delayMs)
    }

    @Test
    fun parseInstruction_acceptsIntArguments() {
        // Flutter's standard codec can send Dart ints across as Kotlin
        // Int rather than Long depending on magnitude -- both must work.
        val map = mapOf("intensity" to 0.5, "durationMs" to 100, "delayMs" to 20)
        val parsed = HapticCompiler.parseInstruction(map)

        assertEquals(100L, parsed.durationMs)
        assertEquals(20L, parsed.delayMs)
    }

    @Test
    fun parseInstruction_missingFieldsUseDefaults() {
        val parsed = HapticCompiler.parseInstruction(emptyMap<String, Any>())

        assertEquals(1.0, parsed.intensity)
        assertEquals(0L, parsed.durationMs)
        assertEquals(0L, parsed.delayMs)
    }

    @Test
    fun parseInstructions_skipsNonMapEntries() {
        val raw = listOf(mapOf("intensity" to 1.0), "not a map", 42)
        val parsed = HapticCompiler.parseInstructions(raw)

        assertEquals(1, parsed.size)
    }

    @Test
    fun amplitudeFor_scalesToAndroidRange() {
        assertEquals(255, HapticCompiler.amplitudeFor(1.0))
        assertEquals(128, HapticCompiler.amplitudeFor(0.5))
    }

    @Test
    fun amplitudeFor_neverReturnsZeroForNonzeroIntensity() {
        // A very small but nonzero intensity should still be felt --
        // amplitude 0 means silent in Android's API.
        assertEquals(1, HapticCompiler.amplitudeFor(0.001))
    }

    @Test
    fun amplitudeFor_clampsOutOfRangeInput() {
        assertEquals(255, HapticCompiler.amplitudeFor(1.5))
        assertEquals(1, HapticCompiler.amplitudeFor(-0.5))
    }

    @Test
    fun toTimingsAndAmplitudes_singleTransientEventGetsMinimumDuration() {
        val instructions = listOf(ParsedInstruction(intensity = 1.0, durationMs = 0, delayMs = 0))
        val (timings, amplitudes) = HapticCompiler.toTimingsAndAmplitudes(instructions)

        assertEquals(listOf(0L, HapticCompiler.MIN_TAP_DURATION_MS), timings.toList())
        assertEquals(listOf(0, 255), amplitudes.toList())
    }

    @Test
    fun toTimingsAndAmplitudes_preservesExplicitDuration() {
        val instructions = listOf(ParsedInstruction(intensity = 0.5, durationMs = 200, delayMs = 0))
        val (timings, amplitudes) = HapticCompiler.toTimingsAndAmplitudes(instructions)

        assertEquals(listOf(0L, 200L), timings.toList())
        assertEquals(listOf(0, 128), amplitudes.toList())
    }

    @Test
    fun toTimingsAndAmplitudes_encodesDelayAsOffSegment() {
        val instructions =
            listOf(
                ParsedInstruction(intensity = 1.0, durationMs = 0, delayMs = 0),
                ParsedInstruction(intensity = 1.0, durationMs = 0, delayMs = 50),
            )
        val (timings, amplitudes) = HapticCompiler.toTimingsAndAmplitudes(instructions)

        // [off(0), on(tap1), off(50), on(tap2)]
        assertEquals(4, timings.size)
        assertEquals(50L, timings[2])
        assertEquals(0, amplitudes[2])
    }

    @Test
    fun toTimingsAndAmplitudes_multipleInstructionsPreserveOrder() {
        val instructions =
            listOf(
                ParsedInstruction(intensity = 1.0, durationMs = 10, delayMs = 0),
                ParsedInstruction(intensity = 0.5, durationMs = 20, delayMs = 30),
                ParsedInstruction(intensity = 0.25, durationMs = 40, delayMs = 60),
            )
        val (timings, amplitudes) = HapticCompiler.toTimingsAndAmplitudes(instructions)

        assertEquals(listOf(0L, 10L, 30L, 20L, 60L, 40L), timings.toList())
        assertEquals(listOf(0, 255, 0, 128, 0, 64), amplitudes.toList())
    }

    @Test
    fun toTimingsAndAmplitudes_emptyInputProducesEmptyArrays() {
        val (timings, amplitudes) = HapticCompiler.toTimingsAndAmplitudes(emptyList())
        assertTrue(timings.isEmpty())
        assertTrue(amplitudes.isEmpty())
    }

    @Test
    fun toTimingsAndAmplitudes_negativeDelayIsClampedToZero() {
        val instructions = listOf(ParsedInstruction(intensity = 1.0, durationMs = 10, delayMs = -5))
        val (timings, _) = HapticCompiler.toTimingsAndAmplitudes(instructions)
        assertEquals(0L, timings[0])
    }
}
