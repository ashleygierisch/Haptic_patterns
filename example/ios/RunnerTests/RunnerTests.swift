import CoreHaptics
import Flutter
import UIKit
import XCTest

@testable import haptic_patterns

// See https://developer.apple.com/documentation/xctest for more
// information about using XCTest.

final class HapticCompilerTests: XCTestCase {
    func testParseInstructionReadsAllFields() {
        let map: [String: Any] = ["intensity": 0.5, "sharpness": 0.3, "durationMs": 100, "delayMs": 20]
        let parsed = HapticCompiler.parseInstruction(map)

        XCTAssertEqual(parsed.intensity, 0.5)
        XCTAssertEqual(parsed.sharpness, 0.3)
        XCTAssertEqual(parsed.durationMs, 100)
        XCTAssertEqual(parsed.delayMs, 20)
    }

    func testParseInstructionMissingFieldsUseDefaults() {
        let parsed = HapticCompiler.parseInstruction([:])

        XCTAssertEqual(parsed.intensity, 1.0)
        XCTAssertEqual(parsed.sharpness, 0.5)
        XCTAssertEqual(parsed.durationMs, 0)
        XCTAssertEqual(parsed.delayMs, 0)
    }

    func testParseInstructionsSkipsNonDictionaryEntries() {
        let raw: [Any] = [["intensity": 1.0], "not a map", 42]
        let parsed = HapticCompiler.parseInstructions(raw)

        XCTAssertEqual(parsed.count, 1)
    }

    func testToHapticEventsSingleTransientStartsAtZero() {
        let instructions = [ParsedInstruction(intensity: 1.0, sharpness: 0.5, durationMs: 0, delayMs: 0)]
        let events = HapticCompiler.toHapticEvents(instructions)

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].eventType, .hapticTransient)
        XCTAssertEqual(events[0].relativeTime, 0)
    }

    func testToHapticEventsPositiveDurationIsContinuous() {
        let instructions = [ParsedInstruction(intensity: 1.0, sharpness: 0.5, durationMs: 100, delayMs: 0)]
        let events = HapticCompiler.toHapticEvents(instructions)

        XCTAssertEqual(events[0].eventType, .hapticContinuous)
        XCTAssertEqual(events[0].duration, 0.1, accuracy: 0.0001)
    }

    func testToHapticEventsDelayBecomesRelativeTime() {
        let instructions = [
            ParsedInstruction(intensity: 1.0, sharpness: 0.5, durationMs: 0, delayMs: 0),
            ParsedInstruction(intensity: 1.0, sharpness: 0.5, durationMs: 0, delayMs: 50),
        ]
        let events = HapticCompiler.toHapticEvents(instructions)

        XCTAssertEqual(events[0].relativeTime, 0)
        XCTAssertEqual(events[1].relativeTime, 0.05, accuracy: 0.0001)
    }

    func testToHapticEventsContinuousDurationAdvancesTheClock() {
        // A 100ms continuous event followed by a 50ms delay should put
        // the next event at 150ms, not 50ms -- the delay is measured
        // from when the continuous event actually finishes.
        let instructions = [
            ParsedInstruction(intensity: 1.0, sharpness: 0.5, durationMs: 100, delayMs: 0),
            ParsedInstruction(intensity: 1.0, sharpness: 0.5, durationMs: 0, delayMs: 50),
        ]
        let events = HapticCompiler.toHapticEvents(instructions)

        XCTAssertEqual(events[1].relativeTime, 0.15, accuracy: 0.0001)
    }

    func testToHapticEventsMapsIntensityAndSharpness() {
        let instructions = [ParsedInstruction(intensity: 0.75, sharpness: 0.25, durationMs: 0, delayMs: 0)]
        let events = HapticCompiler.toHapticEvents(instructions)

        let intensity = events[0].eventParameters.first { $0.parameterID == .hapticIntensity }
        let sharpness = events[0].eventParameters.first { $0.parameterID == .hapticSharpness }

        XCTAssertEqual(intensity?.value, 0.75, accuracy: 0.0001)
        XCTAssertEqual(sharpness?.value, 0.25, accuracy: 0.0001)
    }

    func testToHapticEventsClampsOutOfRangeValues() {
        let instructions = [ParsedInstruction(intensity: 1.5, sharpness: -0.5, durationMs: 0, delayMs: 0)]
        let events = HapticCompiler.toHapticEvents(instructions)

        let intensity = events[0].eventParameters.first { $0.parameterID == .hapticIntensity }
        let sharpness = events[0].eventParameters.first { $0.parameterID == .hapticSharpness }

        XCTAssertEqual(intensity?.value, 1.0, accuracy: 0.0001)
        XCTAssertEqual(sharpness?.value, 0.0, accuracy: 0.0001)
    }

    func testToHapticEventsEmptyInputProducesNoEvents() {
        XCTAssertTrue(HapticCompiler.toHapticEvents([]).isEmpty)
    }

    func testToPatternReturnsNilForEmptyInstructions() throws {
        let pattern = try HapticCompiler.toPattern([])
        XCTAssertNil(pattern)
    }

    func testToPatternBuildsAPlayablePattern() throws {
        let raw: [Any] = [["intensity": 1.0, "sharpness": 0.5, "durationMs": 100, "delayMs": 0]]
        let pattern = try HapticCompiler.toPattern(raw)
        XCTAssertNotNil(pattern)
    }
}

final class HapticPatternsPluginTests: XCTestCase {
    func testIsSupportedReturnsABoolWithoutCrashing() {
        // The Simulator (which is what CI runs this against) has no
        // Taptic Engine hardware, so this is expected to report false
        // -- the meaningful thing being tested is that querying
        // hardware capabilities doesn't crash or hang, not a specific
        // device's haptics support.
        let plugin = HapticPatternsPlugin()
        let call = FlutterMethodCall(methodName: "isSupported", arguments: nil)

        let resultExpectation = expectation(description: "result block must be called.")
        plugin.handle(call) { result in
            XCTAssertTrue(result is Bool)
            resultExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testPlayInstructionsWithNonListArgumentsReturnsError() {
        let plugin = HapticPatternsPlugin()
        let call = FlutterMethodCall(methodName: "playInstructions", arguments: "not a list")

        let resultExpectation = expectation(description: "result block must be called.")
        plugin.handle(call) { result in
            guard let error = result as? FlutterError else {
                XCTFail("expected a FlutterError, got \(String(describing: result))")
                return
            }
            XCTAssertEqual(error.code, "INVALID_ARGUMENTS")
            resultExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testPlayInstructionsWithoutHapticsHardwareNoOps() {
        // No haptics hardware on the Simulator -> ensureEngineStarted()
        // returns nil -> playInstructions short-circuits to a
        // successful no-op, matching Android's hasVibrator()==false
        // short-circuit rather than erroring.
        let plugin = HapticPatternsPlugin()
        let instructions: [Any] = [["intensity": 1.0, "durationMs": 0, "delayMs": 0]]
        let call = FlutterMethodCall(methodName: "playInstructions", arguments: instructions)

        let resultExpectation = expectation(description: "result block must be called.")
        plugin.handle(call) { result in
            XCTAssertNil(result)
            resultExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testStopWithNoActivePlayerDoesNotCrash() {
        let plugin = HapticPatternsPlugin()
        let call = FlutterMethodCall(methodName: "stop", arguments: nil)

        let resultExpectation = expectation(description: "result block must be called.")
        plugin.handle(call) { result in
            XCTAssertNil(result)
            resultExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testUnknownMethodIsNotImplemented() {
        let plugin = HapticPatternsPlugin()
        let call = FlutterMethodCall(methodName: "bogus", arguments: nil)

        let resultExpectation = expectation(description: "result block must be called.")
        plugin.handle(call) { result in
            XCTAssertTrue((result as AnyObject) === (FlutterMethodNotImplemented as AnyObject))
            resultExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
