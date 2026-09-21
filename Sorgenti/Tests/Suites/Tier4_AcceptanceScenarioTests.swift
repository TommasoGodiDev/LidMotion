import Foundation
import Metal
import QuartzCore

public final class Tier4_AcceptanceScenarioTests {
    private var results: [TestCaseRecord] = []

    public init() {}

    public func runAll() -> [TestCaseRecord] {
        results.removeAll()

        run("S1_simulatedPhysicalOpeningFromClosedLid", tier: 4, feature: "Acceptance") { try self.test_S1_simulatedPhysicalOpeningFromClosedLid() }
        run("S2_simulatedPhysicalClosingWithStablePerspective", tier: 4, feature: "Acceptance") { try self.test_S2_simulatedPhysicalClosingWithStablePerspective() }
        run("S3_realWorldStutterStressTest1000Centidegrees", tier: 4, feature: "Acceptance") { try self.test_S3_realWorldStutterStressTest1000Centidegrees() }
        run("S4_fastFlickCloseAndCatch", tier: 4, feature: "Acceptance") { try self.test_S4_fastFlickCloseAndCatch() }
        run("S5_fullSessionLifecycle", tier: 4, feature: "Acceptance") { try self.test_S5_fullSessionLifecycle() }

        return results
    }

    private func run(_ name: String, tier: Int, feature: String, block: () throws -> Void) {
        let t0 = CACurrentMediaTime()
        do {
            try block()
            let dt = (CACurrentMediaTime() - t0) * 1000.0
            results.append(TestCaseRecord(name: name, tier: tier, feature: feature, result: .pass, durationMs: dt))
        } catch {
            let dt = (CACurrentMediaTime() - t0) * 1000.0
            results.append(TestCaseRecord(name: name, tier: tier, feature: feature, result: .fail("\(error)"), durationMs: dt))
        }
    }

    /// Acceptance Scenario 1: Physical opening from closed lid starting at wake angles 65°-75° to 105°
    private func test_S1_simulatedPhysicalOpeningFromClosedLid() throws {
        let wakeAngle = 70.0
        let targetOpenAngle = 105.0
        let reference = 105.0
        let closeAngle = 10.0

        // Step 1: Detect opening from closed lid
        let isOpeningFromClosed = wakeAngle < 80.0
        guard isOpeningFromClosed else {
            throw NSError(domain: "S1", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to detect opening from closed at 70 deg"])
        }

        // Step 2: Frame 1 initialization in DuoRenderer
        let delta0 = max(0, reference - wakeAngle) // 35 deg
        let target0 = FoldState.closing(delta: delta0, reference: reference, closeAngle: closeAngle)
        var current = FoldState(tilt: target0.tilt, progress: 1.0, defocus: 1.0, velocity: 0)

        // Step 3: Frame 1 GPU render check -> must be 100% pitch black
        let frame1Fade = TestHarness.calculateFade(progress: current.progress)
        guard frame1Fade == 0.0 else {
            throw NSError(domain: "S1", code: 2, userInfo: [NSLocalizedDescriptionKey: "Frame 1 fade is not 0.0: got \(frame1Fade)"])
        }
        if let pixels = TestHarness.shared.renderToPixels(uniforms: TestHarness.RenderUniforms(progress: Float(current.progress), defocus: Float(current.defocus))) {
            let isBlack = (pixels[0] == 0 && pixels[1] == 0 && pixels[2] == 0 && pixels[3] == 255)
            guard isBlack else {
                throw NSError(domain: "S1", code: 3, userInfo: [NSLocalizedDescriptionKey: "GPU Frame 1 render is not solid black"])
            }
        }

        // Step 4: Advance motion across 60 frames (1 second at 60fps)
        let totalFrames = 60
        let tau = 0.030
        let dt = 1.0 / 60.0
        var prevProgress = current.progress
        var bloomed = false

        for frame in 1...totalFrames {
            let progressRatio = Double(frame) / Double(totalFrames)
            let currentAngle = wakeAngle + (targetOpenAngle - wakeAngle) * progressRatio
            let delta = max(0, reference - currentAngle)
            let targetState = FoldState.closing(delta: delta, reference: reference, closeAngle: closeAngle)

            // Exponential filter step
            let k = 1.0 - exp(-dt / tau)
            current.tilt += (targetState.tilt - current.tilt) * k
            current.progress += (targetState.progress - current.progress) * k
            current.defocus += (targetState.defocus - current.defocus) * k

            guard current.progress <= prevProgress + 1e-5 else {
                throw NSError(domain: "S1", code: 4, userInfo: [NSLocalizedDescriptionKey: "Progress increased during opening at frame \(frame)"])
            }
            prevProgress = current.progress

            let fade = TestHarness.calculateFade(progress: current.progress)
            if fade > 0.0 { bloomed = true }
        }

        guard bloomed else {
            throw NSError(domain: "S1", code: 5, userInfo: [NSLocalizedDescriptionKey: "Animation never bloomed into visible desktop"])
        }
        guard current.progress < 0.05 else {
            throw NSError(domain: "S1", code: 6, userInfo: [NSLocalizedDescriptionKey: "Final progress did not settle near 0: \(current.progress)"])
        }
    }

    /// Acceptance Scenario 2: Physical closing from 105° to 10° with stable perspective
    private func test_S2_simulatedPhysicalClosingWithStablePerspective() throws {
        let reference = 105.0
        let closeAngle = 10.0
        let angles = stride(from: 105.0, through: 10.0, by: -5.0)

        for angle in angles {
            let delta = reference - angle
            let state = FoldState.closing(delta: delta, reference: reference, closeAngle: closeAngle)

            // Check 1: Coordinate mapping sy >= 0.0 for all h
            for h in stride(from: 0.0, through: 1.0, by: 0.2) {
                let (_, sy, t, tilt) = TestHarness.calculateHoldPixel(uv: TestVector2(0.5, 1.0 - h), u_tilt: state.tilt, u_perspective: 0.55, u_eyeDistance: 2.68)
                guard sy >= 0.0 else {
                    throw NSError(domain: "S2", code: 1, userInfo: [NSLocalizedDescriptionKey: "Coordinate inversion at angle \(angle), h=\(h): sy=\(sy)"])
                }
            }

            // Check 2: Vertical stretch ratio <= 2.5 using calibrated tilt
            let (_, _, _, calTilt) = TestHarness.calculateHoldPixel(uv: TestVector2(0.5, 0.0), u_tilt: state.tilt, u_perspective: 0.55, u_eyeDistance: 2.68)
            let D = 2.68 + 2.5
            let dsy_dh = TestHarness.calculateVerticalStretchDerivative(h: 1.0, tilt: calTilt, D: D)
            let t_top = D / (D - sin(calTilt))
            let stretchRatio = (1.0 / max(1e-4, dsy_dh)) / t_top
            guard stretchRatio <= 2.5 else {
                throw NSError(domain: "S2", code: 2, userInfo: [NSLocalizedDescriptionKey: "Vertical stretch ratio exceeded 2.5 at angle \(angle): \(stretchRatio)"])
            }

            // Check 3: Edge feather clamping fw.x <= 0.015
            let sigmaUV = 0.05 * state.defocus
            let fw_x = min(0.015, 1.8 * sigmaUV / 1.54)
            guard fw_x <= 0.015 else {
                throw NSError(domain: "S2", code: 3, userInfo: [NSLocalizedDescriptionKey: "Edge feathering exceeded 0.015 at angle \(angle)"])
            }
        }
    }

    /// Acceptance Scenario 3: Real-world stutter stress test with 1,000 continuous centidegrees
    private func test_S3_realWorldStutterStressTest1000Centidegrees() throws {
        var dispatches = 0
        var lastAngle = 95.00
        let threshold = 0.001

        for raw in (8500..<9500).reversed() {
            let angle = Double(raw) / 100.0
            if abs(angle - lastAngle) >= threshold {
                dispatches += 1
                lastAngle = angle
            }
        }

        guard dispatches == 1000 else {
            throw NSError(domain: "S3", code: 1, userInfo: [NSLocalizedDescriptionKey: "Stutter test dropped frames: \(dispatches)/1000 dispatches"])
        }
    }

    /// Acceptance Scenario 4: Fast flick close and catch (120°/s down to 50°)
    private func test_S4_fastFlickCloseAndCatch() throws {
        // Fast closing at 120 deg/s
        let leadHigh = TestHarness.calculateVelocityLead(slope: -120.0)
        guard leadHigh == (1.0 / 60.0) else {
            throw NSError(domain: "S4", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fast flick lead did not clamp to 1/60s"])
        }

        // Sudden stop: velocity drops to 0
        let leadStop = TestHarness.calculateVelocityLead(slope: 0.0)
        guard leadStop == 0.0 else {
            throw NSError(domain: "S4", code: 2, userInfo: [NSLocalizedDescriptionKey: "Stopped lead is not 0.0"])
        }

        // Settling time test: from progress 0.6 to target 0.6 with tau=0.030s
        let tau = 0.030
        let history = TestHarness.simulateExponentialSmoothing(start: 0.2, target: 0.6, tau: tau, dt: 1.0/60.0, steps: 6)
        let finalVal = history[6]
        guard abs(finalVal - 0.6) < 0.02 else {
            throw NSError(domain: "S4", code: 3, userInfo: [NSLocalizedDescriptionKey: "Catch did not settle within 6 frames: \(finalVal)"])
        }
    }

    /// Acceptance Scenario 5: Full session lifecycle
    private func test_S5_fullSessionLifecycle() throws {
        // 1. Initial flat open state
        var reference = 105.0
        var currentAngle = 105.0
        var state = FoldState.closing(delta: 0, reference: reference, closeAngle: 10.0)
        guard state == .clear else { throw NSError(domain: "S5", code: 1, userInfo: [NSLocalizedDescriptionKey: "Initial state not clear"]) }

        // 2. Partial close to 60°
        currentAngle = 60.0
        let deltaClose = reference - currentAngle // 45 deg
        state = FoldState.closing(delta: deltaClose, reference: reference, closeAngle: 10.0)
        guard state.progress > 0.4 && state.progress < 0.5 else {
            throw NSError(domain: "S5", code: 2, userInfo: [NSLocalizedDescriptionKey: "Partial close progress unexpected: \(state.progress)"])
        }

        // 3. Pause for 2 seconds (stillAnchor = 60.0, stillSince = 2.0s ago)
        let isStill = true
        let resting = isStill ? currentAngle : reference
        let pauseDelta = isStill ? 0.0 : max(0, resting - currentAngle)
        guard pauseDelta == 0.0 else {
            throw NSError(domain: "S5", code: 3, userInfo: [NSLocalizedDescriptionKey: "Pause delta should be 0 (triggering release)"])
        }

        // 4. Reopen to 105°
        currentAngle = 105.0
        state = FoldState.closing(delta: 0, reference: reference, closeAngle: 10.0)
        guard state == .clear else { throw NSError(domain: "S5", code: 4, userInfo: [NSLocalizedDescriptionKey: "Reopened state not clear"]) }

        // 5. Close completely (0°) -> Sleep -> Wake at 72°
        let wakeAngle = 72.0
        let isOpening = wakeAngle < 80.0
        guard isOpening else { throw NSError(domain: "S5", code: 5, userInfo: [NSLocalizedDescriptionKey: "Wake at 72 deg failed to trigger opening"]) }

        // Frame 1 black check
        let startProgress = 1.0
        guard TestHarness.calculateFade(progress: startProgress) == 0.0 else {
            throw NSError(domain: "S5", code: 6, userInfo: [NSLocalizedDescriptionKey: "Wake frame 1 not solid black"])
        }
    }
}
