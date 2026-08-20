package com.artisanstudio.haptic_patterns

import android.os.VibrationEffect
import kotlin.math.roundToInt

/**
 * Converts the flattened instruction list sent from Dart into an
 * Android [VibrationEffect].
 *
 * The legacy (but widely compatible, API 26+) Vibrator API only lets
 * you play one [VibrationEffect] per call, so a whole pattern
 * (potentially many instructions with gaps between them) is encoded
 * as a single [VibrationEffect.createWaveform] call: each instruction
 * becomes a (delay-segment, on-segment) pair in the timings/amplitudes
 * arrays, since createWaveform pairs them up index-for-index and
 * amplitude 0 means silent.
 *
 * "sharpness" has no equivalent in this amplitude-only API -- it's
 * primarily a CoreHaptics (iOS) concept. The newer Composition API
 * (`VibrationEffect.Composition`, API 30+) has PRIMITIVE_CLICK/TICK
 * primitives that could approximate it, which would be a reasonable
 * future enhancement, but createWaveform is used here for the widest
 * compatibility given this plugin's minSdk of 24 (createWaveform
 * itself needs API 26; devices below that fall back to a plain
 * on/off vibrate() call in [HapticPatternsPlugin], with no amplitude
 * or waveform shaping at all).
 */
object HapticCompiler {
    /**
     * Minimum duration (ms) given to a transient (durationMs == 0) tap
     * so it's actually perceptible -- Android has no true instantaneous
     * "transient" haptic concept the way iOS's
     * CHHapticEventTypeHapticTransient does.
     */
    const val MIN_TAP_DURATION_MS = 20L

    fun parseInstructions(raw: List<*>): List<ParsedInstruction> =
        raw.mapNotNull { entry -> (entry as? Map<*, *>)?.let(::parseInstruction) }

    fun parseInstruction(map: Map<*, *>): ParsedInstruction =
        ParsedInstruction(
            intensity = map["intensity"].toDoubleOrDefault(1.0),
            durationMs = map["durationMs"].toLongOrDefault(0L),
            delayMs = map["delayMs"].toLongOrDefault(0L),
        )

    /**
     * Builds the (timings, amplitudes) arrays `createWaveform` expects
     * from a flat list of parsed instructions. Pure function, no
     * Android framework dependency -- unit-testable without a device.
     */
    fun toTimingsAndAmplitudes(instructions: List<ParsedInstruction>): Pair<LongArray, IntArray> {
        val timings = mutableListOf<Long>()
        val amplitudes = mutableListOf<Int>()

        for (instruction in instructions) {
            timings.add(instruction.delayMs.coerceAtLeast(0L))
            amplitudes.add(0)

            val duration =
                if (instruction.durationMs > 0) instruction.durationMs else MIN_TAP_DURATION_MS
            timings.add(duration)
            amplitudes.add(amplitudeFor(instruction.intensity))
        }

        return Pair(timings.toLongArray(), amplitudes.toIntArray())
    }

    /** Maps a 0.0-1.0 intensity to Android's 1-255 amplitude range. A
     * nonzero intensity always rounds up to at least 1 (amplitude 0
     * means silent, which would defeat a deliberately-weak-but-present
     * tap). */
    fun amplitudeFor(intensity: Double): Int =
        (intensity.coerceIn(0.0, 1.0) * 255).roundToInt().coerceIn(1, 255)

    /** Returns null if [raw] contains no playable instructions. */
    fun toVibrationEffect(raw: List<*>): VibrationEffect? {
        val instructions = parseInstructions(raw)
        if (instructions.isEmpty()) return null

        val (timings, amplitudes) = toTimingsAndAmplitudes(instructions)
        if (timings.isEmpty()) return null

        return VibrationEffect.createWaveform(timings, amplitudes, -1)
    }
}

data class ParsedInstruction(
    val intensity: Double,
    val durationMs: Long,
    val delayMs: Long,
)

private fun Any?.toDoubleOrDefault(default: Double): Double =
    when (this) {
        is Double -> this
        is Number -> this.toDouble()
        else -> default
    }

private fun Any?.toLongOrDefault(default: Long): Long =
    when (this) {
        is Long -> this
        is Number -> this.toLong()
        else -> default
    }
