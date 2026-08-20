import CoreHaptics
import Flutter
import UIKit

public class HapticPatternsPlugin: NSObject, FlutterPlugin {
    private var engine: CHHapticEngine?
    private var currentPlayer: CHHapticPatternPlayer?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "haptic_patterns", binaryMessenger: registrar.messenger())
        let instance = HapticPatternsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "playInstructions":
            guard let instructions = call.arguments as? [Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected a list of instructions", details: nil))
                return
            }
            playInstructions(instructions, result: result)
        case "stop":
            stop()
            result(nil)
        case "isSupported":
            result(CHHapticEngine.capabilitiesForHardware().supportsHaptics)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func playInstructions(_ instructions: [Any], result: @escaping FlutterResult) {
        guard let engine = ensureEngineStarted() else {
            // No haptics hardware (simulator, most iPads, engine failed
            // to start) -- silently no-op, matching Android's
            // hasVibrator()==false short-circuit rather than erroring.
            result(nil)
            return
        }

        do {
            guard let pattern = try HapticCompiler.toPattern(instructions) else {
                result(nil)
                return
            }
            let player = try engine.makePlayer(with: pattern)
            currentPlayer = player
            try player.start(atTime: CHHapticTimeImmediate)
            result(nil)
        } catch {
            result(FlutterError(code: "PLAYBACK_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    private func stop() {
        // Stops just the currently playing pattern, not the whole
        // engine -- mirrors Android's vibrator.cancel(), which leaves
        // the vibrator service ready for the next call rather than
        // tearing it down.
        try? currentPlayer?.stop(atTime: CHHapticTimeImmediate)
    }

    /// Starts (or restarts) the haptic engine, returning nil if this
    /// device has no haptics hardware or the engine fails to start.
    ///
    /// Always (re)issues `start()` rather than trusting a cached
    /// engine's presumed state, since the engine can be stopped out
    /// from under this plugin (backgrounding, audio session
    /// interruptions) between calls -- CHHapticEngine.start() is
    /// documented as safe to call even when already running.
    private func ensureEngineStarted() -> CHHapticEngine? {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return nil }

        let activeEngine: CHHapticEngine
        if let existing = engine {
            activeEngine = existing
        } else {
            guard let newEngine = try? CHHapticEngine() else { return nil }
            newEngine.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            newEngine.stoppedHandler = { _ in }
            engine = newEngine
            activeEngine = newEngine
        }

        do {
            try activeEngine.start()
            return activeEngine
        } catch {
            return nil
        }
    }
}
