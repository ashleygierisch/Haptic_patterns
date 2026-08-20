import CoreHaptics

/// Converts the flattened instruction list sent from Dart into a
/// `CHHapticPattern`.
///
/// Unlike Android's amplitude-only `VibrationEffect` API, CoreHaptics
/// has first-class intensity *and* sharpness parameters, so both map
/// directly with no approximation needed -- `sharpness` in the Dart
/// `HapticEvent` API was modeled on this API in the first place.
enum HapticCompiler {
    static func parseInstructions(_ raw: [Any]) -> [ParsedInstruction] {
        raw.compactMap { entry in
            guard let map = entry as? [String: Any] else { return nil }
            return parseInstruction(map)
        }
    }

    static func parseInstruction(_ map: [String: Any]) -> ParsedInstruction {
        ParsedInstruction(
            intensity: doubleValue(map["intensity"], default: 1.0),
            sharpness: doubleValue(map["sharpness"], default: 0.5),
            durationMs: intValue(map["durationMs"], default: 0),
            delayMs: intValue(map["delayMs"], default: 0)
        )
    }

    /// Builds an array of `CHHapticEvent`s from parsed instructions.
    ///
    /// Each instruction's `delayMs` is relative to the end of the
    /// previous instruction (matching the wire format's semantics --
    /// see the Dart `HapticSequence.compile()` doc comment), so this
    /// accumulates a running clock and converts each instruction into
    /// an absolute `relativeTime`, which is what `CHHapticEvent`
    /// expects. A transient (durationMs == 0) event doesn't advance
    /// the clock beyond its own start, since `.hapticTransient` is
    /// instantaneous; a continuous event advances it by the event's
    /// own duration, so the next instruction's delay is measured from
    /// when this one actually finishes.
    static func toHapticEvents(_ instructions: [ParsedInstruction]) -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        var elapsedSeconds: TimeInterval = 0

        for instruction in instructions {
            elapsedSeconds += Double(instruction.delayMs) / 1000.0

            let parameters = [
                CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: Float(clamp(instruction.intensity, 0, 1))
                ),
                CHHapticEventParameter(
                    parameterID: .hapticSharpness,
                    value: Float(clamp(instruction.sharpness, 0, 1))
                ),
            ]

            if instruction.durationMs > 0 {
                let durationSeconds = Double(instruction.durationMs) / 1000.0
                events.append(
                    CHHapticEvent(
                        eventType: .hapticContinuous,
                        parameters: parameters,
                        relativeTime: elapsedSeconds,
                        duration: durationSeconds
                    )
                )
                elapsedSeconds += durationSeconds
            } else {
                events.append(
                    CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: parameters,
                        relativeTime: elapsedSeconds
                    )
                )
            }
        }

        return events
    }

    /// Returns nil if `raw` contains no playable instructions.
    /// Propagates `CHHapticPattern`'s own construction errors (e.g. an
    /// engine-rejected parameter combination) rather than swallowing
    /// them, so callers can report a real error instead of silently
    /// doing nothing.
    static func toPattern(_ raw: [Any]) throws -> CHHapticPattern? {
        let instructions = parseInstructions(raw)
        guard !instructions.isEmpty else { return nil }

        let events = toHapticEvents(instructions)
        guard !events.isEmpty else { return nil }

        return try CHHapticPattern(events: events, parameters: [])
    }

    private static func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }

    private static func doubleValue(_ value: Any?, default defaultValue: Double) -> Double {
        (value as? NSNumber)?.doubleValue ?? defaultValue
    }

    private static func intValue(_ value: Any?, default defaultValue: Int) -> Int {
        (value as? NSNumber)?.intValue ?? defaultValue
    }
}

struct ParsedInstruction: Equatable {
    let intensity: Double
    let sharpness: Double
    let durationMs: Int
    let delayMs: Int
}
