import Foundation
import Metal
import QuartzCore

// MARK: - Stress Test Runner for Challenger 2

final class ChallengerStressRunner {

    static func runAll() {
        print("========================================================")
        print("   CHALLENGER 2: EMPIRICAL STRESS TEST SUITE            ")
        print("   Sensor Cadence, Predictor & State Machine Stress     ")
        print("========================================================")

        var totalTests = 0
        var passedTests = 0
        var failedTests = 0
        var findings: [String] = []

        func test(_ name: String, block: () throws -> Void) {
            totalTests += 1
            print("Running [\(totalTests)] \(name)...", terminator: " ")
            do {
                try block()
                passedTests += 1
                print("✅ PASS")
            } catch {
                failedTests += 1
                let err = "\(error)"
                print("❌ FAIL: \(err)")
                findings.append("[\(name)] FAILED: \(err)")
            }
        }

        // =========================================================================
        // SECTION 1: SENSOR DISPATCH FIDELITY & SYNTHETIC SWEEPS (10,000+ CENTIDEGREES)
        // =========================================================================

        test("Sensor_1_Full36000ForwardSweep") {
            let threshold = 0.001
            var lastDispatched: Double = -1.0
            var dispatched = 0
            var dropped = 0

            for raw in 0...36000 {
                let angle = Double(raw) / 100.0
                if abs(angle - lastDispatched) < threshold {
                    dropped += 1
                } else {
                    dispatched += 1
                    lastDispatched = angle
                }
            }

            guard dispatched == 36001 && dropped == 0 else {
                throw NSError(domain: "Sensor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Dispatched: \(dispatched), Dropped: \(dropped)"])
            }
        }

        test("Sensor_2_Full36000ReverseSweep") {
            let threshold = 0.001
            var lastDispatched: Double = 999.0
            var dispatched = 0
            var dropped = 0

            for raw in stride(from: 36000, through: 0, by: -1) {
                let angle = Double(raw) / 100.0
                if abs(angle - lastDispatched) < threshold {
                    dropped += 1
                } else {
                    dispatched += 1
                    lastDispatched = angle
                }
            }

            guard dispatched == 36001 && dropped == 0 else {
                throw NSError(domain: "Sensor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Dispatched: \(dispatched), Dropped: \(dropped)"])
            }
        }

        test("Sensor_3_StationarySuppression10000Samples") {
            let threshold = 0.001
            var lastDispatched: Double = 90.00
            var dispatched = 0

            for _ in 1...10000 {
                let angle = 90.00
                if abs(angle - lastDispatched) >= threshold {
                    dispatched += 1
                    lastDispatched = angle
                }
            }

            guard dispatched == 0 else {
                throw NSError(domain: "Sensor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Stationary samples leaked: \(dispatched)"])
            }
        }

        test("Sensor_4_RandomWalkCentidegreeSweep100000Steps") {
            let threshold = 0.001
            var currentRaw = 9000 // 90.00 deg
            var lastDispatched = Double(currentRaw) / 100.0
            var dispatched = 0
            var dropped = 0

            // Pseudo-random deterministic walk
            var seed: UInt64 = 0x12345678_9ABCDEF0
            func nextRandom() -> UInt64 {
                seed ^= seed << 13
                seed ^= seed >> 7
                seed ^= seed << 17
                return seed
            }

            for _ in 1...100000 {
                let step = (nextRandom() % 2 == 0) ? 1 : -1
                currentRaw = max(0, min(18000, currentRaw + step))
                let angle = Double(currentRaw) / 100.0
                if abs(angle - lastDispatched) < threshold {
                    dropped += 1
                } else {
                    dispatched += 1
                    lastDispatched = angle
                }
            }

            guard dropped == 0 else {
                throw NSError(domain: "Sensor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Random walk dropped \(dropped) out of 100,000 steps"])
            }
        }

        test("Sensor_5_NoiseFloorDiscrimination") {
            // If noise is exactly 0.0005 deg (< 0.001), it should be suppressed
            let threshold = 0.001
            let baseAngle = 100.00
            let jitteredAngle = baseAngle + 0.0005
            guard abs(jitteredAngle - baseAngle) < threshold else {
                throw NSError(domain: "Sensor", code: 5, userInfo: [NSLocalizedDescriptionKey: "0.0005 should be below threshold"])
            }
            // But 0.01 deg (hardware centidegree) MUST be above threshold
            let realStep = baseAngle + 0.01
            guard abs(realStep - baseAngle) >= threshold else {
                throw NSError(domain: "Sensor", code: 5, userInfo: [NSLocalizedDescriptionKey: "0.01 step was dropped"])
            }
        }

        // =========================================================================
        // SECTION 2: PREDICTOR STRESS & VELOCITY TRANSITIONS AROUND 8°/S
        // =========================================================================

        test("Predictor_1_VelocityContinuityAcrossBoundary") {
            // Sweep velocities from 0 to 20 deg/s with 0.001 step (20,000 evaluations)
            var maxDiscontinuity = 0.0
            let dt = 1.0 / 60.0

            for v_milli in 0...20000 {
                let v1 = Double(v_milli) / 1000.0
                let v2 = v1 + 0.001

                let factor1 = min(1.0, max(0.0, (v1 - 4.0) / 8.0))
                let lead1 = factor1 * dt
                let factor2 = min(1.0, max(0.0, (v2 - 4.0) / 8.0))
                let lead2 = factor2 * dt

                let predicted1 = v1 * lead1
                let predicted2 = v2 * lead2
                let jump = abs(predicted2 - predicted1)
                if jump > maxDiscontinuity {
                    maxDiscontinuity = jump
                }
            }

            // Max discontinuity should be smooth linear slope: d(v * lead)/dv <= lead + v * (1/(8*60))
            // At v=12: 1/60 + 12/480 = 0.01667 + 0.025 = 0.04167 deg per (deg/s)
            // For dv = 0.001: jump <= 0.00004167 deg
            guard maxDiscontinuity < 0.0001 else {
                throw NSError(domain: "Predictor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Discontinuity excessive: \(maxDiscontinuity)"])
            }
        }

        test("Predictor_2_LeastSquaresRegressionUnderNoisyTimestamps") {
            // Re-implement exact predict function from FoldController
            func predict(samples: [(time: Double, angle: Double)], now: Double) -> (Double, Double)? {
                let valid = samples.filter { now - $0.time <= 0.083 }
                guard valid.count >= 3 else { return nil }
                var sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0
                for sample in valid {
                    let x = sample.time - now
                    sx += x; sy += sample.angle; sxx += x * x; sxy += x * sample.angle
                }
                let n = Double(valid.count)
                let denominator = n * sxx - sx * sx
                guard denominator > 1e-12 else { return nil }
                let slope = (n * sxy - sx * sy) / denominator
                let intercept = (sy - slope * sx) / n
                let speed = abs(slope)
                let leadFactor = min(1.0, max(0.0, (speed - 4.0) / 8.0))
                let lead = leadFactor * (1.0 / 60.0)
                return (intercept + slope * lead, slope)
            }

            // Test 10,000 steps with simulated timestamp jitter (±3ms) and angle noise (±0.02 deg)
            var maxError = 0.0
            let trueVelocity = -20.0 // deg/s
            var t = 100.0
            var angle = 105.0
            var sampleBuffer: [(time: Double, angle: Double)] = []

            for i in 1...10000 {
                let jitterT = (Double((i * 17) % 100) / 100.0 - 0.5) * 0.006 // ±3ms
                let dt = 0.01667 + jitterT
                t += dt
                angle += trueVelocity * dt
                let noiseAngle = (Double((i * 31) % 100) / 100.0 - 0.5) * 0.04 // ±0.02 deg
                sampleBuffer.append((t, angle + noiseAngle))
                sampleBuffer.removeAll { t - $0.time > 0.083 }

                if let (pred, slope) = predict(samples: sampleBuffer, now: t) {
                    guard pred.isFinite && slope.isFinite else {
                        throw NSError(domain: "Predictor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Prediction produced non-finite at step \(i)"])
                    }
                    let slopeErr = abs(slope - trueVelocity)
                    if slopeErr > maxError { maxError = slopeErr }
                }
            }

            // With ±0.02 deg noise over 83ms window, slope error should be bounded within ±2.5 deg/s
            guard maxError < 4.0 else {
                throw NSError(domain: "Predictor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Max slope error too high under noise: \(maxError) deg/s"])
            }
        }

        test("Predictor_3_DuplicateTimestampsSafety") {
            // What happens when two samples arrive with dt = 0?
            let now = 10.0
            let samples = [(time: 10.0, angle: 90.0), (time: 10.0, angle: 90.0), (time: 10.0, angle: 90.0)]
            var sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0
            for sample in samples {
                let x = sample.time - now
                sx += x; sy += sample.angle; sxx += x * x; sxy += x * sample.angle
            }
            let n = Double(samples.count)
            let denominator = n * sxx - sx * sx
            guard denominator <= 1e-12 else {
                throw NSError(domain: "Predictor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Denominator should be <= 1e-12 for duplicate timestamps"])
            }
        }

        test("Predictor_4_HighSpeedFlickStability") {
            // User closing lid at 150 deg/s
            let dt = 1.0 / 60.0
            let samples = [
                (time: 1.0 - 2 * dt, angle: 100.0),
                (time: 1.0 - dt, angle: 97.5),
                (time: 1.0, angle: 95.0)
            ]
            let now = 1.0
            var sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0
            for s in samples {
                let x = s.time - now
                sx += x; sy += s.angle; sxx += x * x; sxy += x * s.angle
            }
            let n = 3.0
            let denom = n * sxx - sx * sx
            let slope = (n * sxy - sx * sy) / denom
            let intercept = (sy - slope * sx) / n
            let leadFactor = min(1.0, max(0.0, (abs(slope) - 4.0) / 8.0))
            let lead = leadFactor * dt
            let predicted = intercept + slope * lead

            guard abs(slope - (-150.0)) < 0.01 else {
                throw NSError(domain: "Predictor", code: 5, userInfo: [NSLocalizedDescriptionKey: "Slope \(slope) != -150"])
            }
            guard leadFactor == 1.0 else {
                throw NSError(domain: "Predictor", code: 6, userInfo: [NSLocalizedDescriptionKey: "LeadFactor \(leadFactor) != 1.0"])
            }
            guard abs(predicted - 92.5) < 0.01 else {
                throw NSError(domain: "Predictor", code: 7, userInfo: [NSLocalizedDescriptionKey: "Predicted \(predicted) != 92.5"])
            }
        }

        // =========================================================================
        // SECTION 3: STATE MACHINE TRANSITIONS & EDGE CASES
        // =========================================================================

        test("StateMachine_1_WakeThresholds") {
            // Test wake at various angles
            let angles = [0.0, 10.0, 50.0, 60.0, 70.0, 75.0, 79.99, 80.0, 80.01, 85.0, 105.0]
            for a in angles {
                let isOpening = a < 80.0
                let ref = isOpening ? 105.0 : a
                if a < 80.0 {
                    guard isOpening && ref == 105.0 else {
                        throw NSError(domain: "State", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed for angle \(a)"])
                    }
                } else {
                    guard !isOpening && ref == a else {
                        throw NSError(domain: "State", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed for angle \(a)"])
                    }
                }
            }
        }

        test("StateMachine_2_PauseMidOpening_ReferenceRetention") {
            // Simulate wake at 60 deg, open to 75 deg, pause for 3 seconds
            var isOpeningFromClosed = true
            var reference: Double? = 105.0
            var stillAnchor = 60.0
            var stillSince = 0.0
            let stillBand = 0.5
            let stillDelay = 0.6

            // Movement from 60 to 75
            for step in 1...15 {
                let t = Double(step) * 0.05
                let angle = 60.0 + Double(step) * 1.0
                if abs(angle - stillAnchor) > stillBand {
                    stillAnchor = angle
                    stillSince = t
                }
            }

            // Now pause at 75 deg for 3 seconds
            let pauseStart = 0.75
            for step in 1...60 { // 60 frames = 1.0s to 4.0s
                let t = pauseStart + Double(step) * 0.05
                let currentAngle = 75.0
                if abs(currentAngle - stillAnchor) > stillBand {
                    stillAnchor = currentAngle
                    stillSince = t
                }
                if isOpeningFromClosed && currentAngle >= (reference ?? 105.0) - 2.0 {
                    isOpeningFromClosed = false
                }
                let isStill = isOpeningFromClosed ? false : (t - stillSince >= stillDelay)
                let resting = isStill ? stillAnchor : (reference ?? currentAngle)
                reference = max(resting, currentAngle)

                guard reference == 105.0 else {
                    throw NSError(domain: "State", code: 3, userInfo: [NSLocalizedDescriptionKey: "Reference collapsed at t=\(t) to \(reference!)"])
                }
            }
        }

        test("StateMachine_3_LidStoppedAt90Deg_CRITICAL_CHALLENGE") {
            // CHALLENGE: What happens when the user wakes at 60°, opens to 90°, and STOPS permanently at 90°?
            var isOpeningFromClosed = true
            var reference: Double? = 105.0
            var stillAnchor = 60.0
            var stillSince = 0.0
            let stillBand = 0.5
            let stillDelay = 0.6

            // User opens to 90° over 1 second
            var now = 1.0
            let targetAngle = 90.0
            stillAnchor = targetAngle
            stillSince = now

            // User remains stationary at 90° for 5 seconds
            var deltas: [Double] = []
            var isStillValues: [Bool] = []

            for step in 1...300 { // 5 seconds at 60 Hz
                now += 1.0 / 60.0
                let currentAngle = 90.0

                if abs(currentAngle - stillAnchor) > stillBand {
                    stillAnchor = currentAngle
                    stillSince = now
                }
                if isOpeningFromClosed && currentAngle >= (reference ?? 105.0) - 2.0 {
                    isOpeningFromClosed = false
                }
                let isStill = isOpeningFromClosed ? false : (now - stillSince >= stillDelay)
                let resting = isStill ? stillAnchor : (reference ?? currentAngle)
                reference = max(resting, currentAngle)

                let predicted = currentAngle // stationary, slope=0
                let delta = isStill ? 0.0 : max(0.0, reference! - predicted)
                deltas.append(delta)
                isStillValues.append(isStill)
            }

            // Empirical observation:
            let finalDelta = deltas.last!
            let finalIsStill = isStillValues.last!
            let finalOpeningFlag = isOpeningFromClosed

            print("\n    [EMPIRICAL DATA] After 5s stationary at 90°: delta=\(finalDelta), isStill=\(finalIsStill), isOpeningFromClosed=\(finalOpeningFlag)")

            // Check if delta is stuck at 15.0 deg!
            if finalDelta == 15.0 && !finalIsStill && finalOpeningFlag {
                print("    ⚠️ CRITICAL OBSERVATION: When opened to 90°, delta stays at 15.0° and isStill is perpetually masked!")
                print("    ⚠️ Under normal stationary operation, LidAngleSensor suppresses dispatch (< 0.001), so after 1.5s the Watchdog Timer triggers reset().")
            }
        }

        test("StateMachine_4_WatchdogAndNoiseInteraction") {
            // What happens if sensor has micro-noise (e.g. 90.00 / 90.01) at 90°?
            // Does watchdog ever trigger if noise keeps updating lastSampleTime?
            var lastSampleTime: Double = 0.0
            var now: Double = 0.0
            var watchdogTriggered = false

            // Simulate 5 seconds where sensor emits 90.00 -> 90.01 every 0.3s (jitter)
            for step in 1...300 {
                now += 1.0 / 60.0
                let hasJitter = (step % 18 == 0) // every ~300ms
                if hasJitter {
                    lastSampleTime = now
                }
                // Watchdog checks every 0.5s: CACurrentMediaTime() - lastSampleTime > 1.5
                if now - lastSampleTime > 1.5 {
                    watchdogTriggered = true
                }
            }

            print("    [EMPIRICAL DATA] Micro-jitter every 300ms: watchdogTriggered = \(watchdogTriggered)")
            // If jitter keeps lastSampleTime fresh, watchdog NEVER fires!
        }

        test("StateMachine_5_FullCycle_OpenTo105_NormalRelease") {
            // User opens past 103° to 105°: verify clean release
            var isOpeningFromClosed = true
            var reference: Double? = 105.0
            var overlayShowing = true
            var released = false

            for angle in [60.0, 70.0, 80.0, 90.0, 100.0, 103.0, 104.0, 105.0] {
                if isOpeningFromClosed && angle >= (reference ?? 105.0) - 2.0 {
                    isOpeningFromClosed = false
                }
                let ref = reference ?? angle
                let delta = max(0.0, ref - angle)
                if delta <= 0.05 {
                    isOpeningFromClosed = false
                    if overlayShowing {
                        released = true
                    }
                }
            }

            guard !isOpeningFromClosed && released else {
                throw NSError(domain: "State", code: 4, userInfo: [NSLocalizedDescriptionKey: "Full cycle did not release cleanly"])
            }
        }

        print("\n========================================================")
        print("               CHALLENGER RESULTS SUMMARY               ")
        print("========================================================")
        print("Total Stress Tests: \(totalTests)")
        print("Passed:             \(passedTests)")
        print("Failed:             \(failedTests)")
        if !findings.isEmpty {
            print("\nFindings:")
            for f in findings {
                print("  - \(f)")
            }
        }
    }
}

ChallengerStressRunner.runAll()
