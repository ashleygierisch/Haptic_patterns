package com.artisanstudio.haptic_patterns

import android.content.Context
import android.os.Build
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** HapticPatternsPlugin */
class HapticPatternsPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    // internal (not private) so tests can assign a fake HapticVibrator
    // directly, bypassing onAttachedToEngine's Context plumbing.
    internal lateinit var vibrator: HapticVibrator

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "haptic_patterns")
        channel.setMethodCallHandler(this)
        vibrator = SystemHapticVibrator(getVibrator(flutterPluginBinding.applicationContext))
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        when (call.method) {
            "playInstructions" -> {
                val instructions = call.arguments as? List<*>
                if (instructions == null) {
                    result.error("INVALID_ARGUMENTS", "Expected a list of instructions", null)
                    return
                }
                playInstructions(instructions)
                result.success(null)
            }
            "stop" -> {
                vibrator.cancel()
                result.success(null)
            }
            "isSupported" -> {
                result.success(vibrator.hasVibrator())
            }
            else -> result.notImplemented()
        }
    }

    private fun playInstructions(instructions: List<*>) {
        if (!vibrator.hasVibrator()) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = HapticCompiler.toVibrationEffect(instructions)
            if (effect != null) vibrator.vibrate(effect)
        } else {
            // API 24-25 predates VibrationEffect entirely -- fall back
            // to the legacy timings-only API with no amplitude control.
            // Delay segments are encoded the same way (alternating
            // off/on durations); on-segments just can't be scaled by
            // intensity here.
            val parsed = HapticCompiler.parseInstructions(instructions)
            if (parsed.isEmpty()) return
            val (timings, _) = HapticCompiler.toTimingsAndAmplitudes(parsed)
            if (timings.isEmpty()) return

            vibrator.vibrateLegacy(timings, -1)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    companion object {
        fun getVibrator(context: Context): Vibrator =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager =
                    context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                manager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
    }
}
