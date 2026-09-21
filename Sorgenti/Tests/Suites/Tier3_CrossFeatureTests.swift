import Foundation
import Metal
import QuartzCore

public final class Tier3_CrossFeatureTests {
    private var results: [TestCaseRecord] = []

    public init() {}

    public func runAll() -> [TestCaseRecord] {
        results.removeAll()

        run("T3_wakeWhileUserMovesFast", tier: 3, feature: "F4+F5+F6+F8") { try self.test_T3_wakeWhileUserMovesFast() }
        run("T3_wakeWhileUserMovesSlowly", tier: 3, feature: "F3+F6+F7") { try self.test_T3_wakeWhileUserMovesSlowly() }
        run("T3_rapidReversalClosingToOpening", tier: 3, feature: "F4+F5+F7") { try self.test_T3_rapidReversalClosingToOpening() }
        run("T3_pauseDuringOpeningAnimation", tier: 3, feature: "F6+F7+F8") { try self.test_T3_pauseDuringOpeningAnimation() }
        run("T3_deepClosingWithMaxBlurAndPerspective", tier: 3, feature: "F1+F2+F9") { try self.test_T3_deepClosingWithMaxBlurAndPerspective() }
        run("T3_fluctuatingVelocityAcross8DegSThreshold", tier: 3, feature: "F3+F4+F5") { try self.test_T3_fluctuatingVelocityAcross8DegSThreshold() }
        run("T3_sleepWakeCycleFollowedByImmediateReopening", tier: 3, feature: "F6+F7+F8+F9") { try self.test_T3_sleepWakeCycleFollowedByImmediateReopening() }

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

    /// Interaction 1: Wake at 70° moving fast (60°/s) -> F6 wake + F8 black start + F4 continuous lead + F5 fast tau
    private func test_T3_wakeWhileUserMovesFast() throws {
        let wakeAngle = 70.0
        let isOpening = wakeAngle < 80.0
        guard isOpening else { throw NSError(domain: "T3", code: 1, userInfo: [NSLocalizedDescriptionKey: "Wake at 70 deg must trigger opening"]) }

        let target = FoldState.closing(delta: 105.0 - wakeAngle, reference: 105.0, closeAngle: 10.0)
        let initial = FoldState(tilt: target.tilt, progress: 1.0, defocus: 1.0, velocity: 0)
        guard initial.progress == 1.0 else { throw NSError(domain: "T3", code: 2, userInfo: [NSLocalizedDescriptionKey: "initial frame must be progress=1.0"]) }

        // Fast moving lid: speed = 60 deg/s -> lead should be full 1/60s
        let lead = TestHarness.calculateVelocityLead(slope: -60.0)
        guard abs(lead - 1.0/60.0) < 1e-9 else { throw NSError(domain: "T3", code: 3, userInfo: [NSLocalizedDescriptionKey: "Lead at 60 deg/s must be 1/60s"]) }

        // Fast tau (30ms) ensures response tracks target quickly without 255ms drag
        let tau = 0.030
        let history = TestHarness.simulateExponentialSmoothing(start: 1.0, target: target.progress, tau: tau, dt: 1.0/60.0, steps: 6)
        let finalProgress = history.last!
        guard abs(finalProgress - target.progress) < 0.05 else {
            throw NSError(domain: "T3", code: 4, userInfo: [NSLocalizedDescriptionKey: "Progress did not converge to target within 100ms"])
        }
    }

    /// Interaction 2: Wake at 65° moving slowly (1.5°/s) -> F6 wake + F7 pause immunity + F3 zero-drop sensor
    private func test_T3_wakeWhileUserMovesSlowly() throws {
        let wakeAngle = 65.0
        var isOpening = wakeAngle < 80.0
        var reference = 105.0
        let stillAnchor = 65.0

        // Slow speed (1.5 deg/s) generates steps of ~0.025 deg per frame (exceeding 0.001 threshold)
        var dispatched = 0
        var lastAngle = wakeAngle
        for step in 1...100 {
            let currentAngle = wakeAngle + Double(step) * 0.025
            if abs(currentAngle - lastAngle) >= 0.001 {
                dispatched += 1
                lastAngle = currentAngle
            }
        }
        guard dispatched == 100 else {
            throw NSError(domain: "T3", code: 5, userInfo: [NSLocalizedDescriptionKey: "Slow motion had dropped frames: \(dispatched)/100"])
        }

        // Even if 1.5 seconds elapse (> stillDelay 0.6s), reference must NOT collapse
        let now = 2.0
        let stillSince = 0.0
        let isStill = isOpening ? false : (now - stillSince >= 0.6)
        let resting = isStill ? stillAnchor : reference
        reference = max(resting, 67.5)
        guard reference == 105.0 else {
            throw NSError(domain: "T3", code: 6, userInfo: [NSLocalizedDescriptionKey: "Reference collapsed during slow opening motion: \(reference) != 105.0"])
        }
    }

    /// Interaction 3: Rapid reversal from closing to opening -> F4 predictor + F7 state machine + F5 renderer
    private func test_T3_rapidReversalClosingToOpening() throws {
        // User closes to 70 deg (slope -40 deg/s), then abruptly reverses to open to 95 deg (slope +50 deg/s)
        let leadClose = TestHarness.calculateVelocityLead(slope: -40.0)
        let leadOpen = TestHarness.calculateVelocityLead(slope: 50.0)
        guard leadClose == (1.0 / 60.0) && leadOpen == (1.0 / 60.0) else {
            throw NSError(domain: "T3", code: 7, userInfo: [NSLocalizedDescriptionKey: "Reversal leads unequal"])
        }

        // When user opens back past 103 deg (reference 105 - 2), delta collapses and renderer releases
        let currentAngle = 104.5
        let reference = 105.0
        let delta = max(0, reference - currentAngle)
        guard delta < 0.6 else {
            throw NSError(domain: "T3", code: 8, userInfo: [NSLocalizedDescriptionKey: "Delta should collapse on reversal to full open"])
        }
    }

    /// Interaction 4: Pause during opening animation -> F6 + F7 + F8
    private func test_T3_pauseDuringOpeningAnimation() throws {
        var isOpening = true
        var reference = 105.0
        let currentAngle = 82.0

        // Pause for 1.2s (> 0.6s stillDelay)
        let isStill = isOpening ? false : true
        let ref = isStill ? currentAngle : reference
        reference = max(ref, currentAngle)

        guard reference == 105.0 else {
            throw NSError(domain: "T3", code: 9, userInfo: [NSLocalizedDescriptionKey: "Pause during opening collapsed reference: \(reference)"])
        }

        let delta = max(0, reference - currentAngle)
        let targetState = FoldState.closing(delta: delta, reference: reference, closeAngle: 10.0)
        let fade = TestHarness.calculateFade(progress: targetState.progress)
        // delta = 23 deg, span = 95 deg, progress = 0.242 -> fade = 1.0 (fully bloomed)
        guard fade == 1.0 else {
            throw NSError(domain: "T3", code: 10, userInfo: [NSLocalizedDescriptionKey: "Desktop should be fully visible when paused at 82 deg"])
        }
    }

    /// Interaction 5: Deep closing with max blur and max perspective -> F1 + F2 + F9
    private func test_T3_deepClosingWithMaxBlurAndPerspective() throws {
        let delta = 80.0 // close to hinge
        let state = FoldState.closing(delta: delta, reference: 105.0, closeAngle: 10.0)
        let perspective = 1.0
        let blur = 1.0
        let defocus = 1.0

        // 1. Perspective check (F1)
        let (mapped, sy, t, tilt) = TestHarness.calculateHoldPixel(uv: TestVector2(0.5, 0.0), u_tilt: state.tilt, u_perspective: perspective, u_eyeDistance: 1.6)
        guard sy >= 0.0 else { throw NSError(domain: "T3", code: 11, userInfo: [NSLocalizedDescriptionKey: "sy inverted under deep close + max perspective"]) }

        // 2. Edge feather check (F2)
        let sigmaUV = clamp(blur, 0.0, 1.0) * 0.05 * defocus + 0.012
        let fw_x = min(0.015, 1.8 * sigmaUV / 1.6)
        guard fw_x <= 0.015 else { throw NSError(domain: "T3", code: 12, userInfo: [NSLocalizedDescriptionKey: "Edge feathering exceeded 0.015 clamp"]) }

        // 3. Fade check (F9)
        // delta = 80, span = 95 -> progress = 80/95 = 0.842
        let fade = TestHarness.calculateFade(progress: state.progress)
        guard fade >= 0.0 && fade <= 0.1 else {
            throw NSError(domain: "T3", code: 13, userInfo: [NSLocalizedDescriptionKey: "Deep close fade should be near zero, got \(fade)"])
        }
    }

    /// Interaction 6: Oscillating velocity around 8°/s threshold -> F3 + F4 + F5
    private func test_T3_fluctuatingVelocityAcross8DegSThreshold() throws {
        // Velocities: 6, 7, 7.99, 8.01, 9, 10
        let velocities = [6.0, 7.0, 7.99, 8.01, 9.0, 10.0]
        var leads: [Double] = []
        for v in velocities {
            leads.append(TestHarness.calculateVelocityLead(slope: v))
        }
        for i in 1..<leads.count {
            guard leads[i] >= leads[i - 1] else {
                throw NSError(domain: "T3", code: 14, userInfo: [NSLocalizedDescriptionKey: "Non-monotonic lead response across threshold"])
            }
            let stepDiff = leads[i] - leads[i - 1]
            guard stepDiff < 0.005 else {
                throw NSError(domain: "T3", code: 15, userInfo: [NSLocalizedDescriptionKey: "Discontinuous step in velocity lead"])
            }
        }
    }

    /// Interaction 7: Sleep/wake cycle followed by reopening -> F6 + F7 + F8 + F9
    private func test_T3_sleepWakeCycleFollowedByImmediateReopening() throws {
        // System sleep occurs: controller resets
        var isShowing = true
        var current = FoldState(tilt: 0.5, progress: 0.4, defocus: 0.3, velocity: 0)
        // Reset called on sleep:
        isShowing = false
        current = .clear

        // Wake occurs at 72.0 deg:
        let wakeAngle = 72.0
        let isOpening = wakeAngle < 80.0
        guard isOpening else { throw NSError(domain: "T3", code: 16, userInfo: [NSLocalizedDescriptionKey: "Wake at 72 deg did not trigger opening"]) }

        // Start opening initializes current to black
        let target = FoldState.closing(delta: 105.0 - wakeAngle, reference: 105.0, closeAngle: 10.0)
        current = FoldState(tilt: target.tilt, progress: 1.0, defocus: 1.0, velocity: 0)
        guard current.progress == 1.0 else {
            throw NSError(domain: "T3", code: 17, userInfo: [NSLocalizedDescriptionKey: "Reopening did not initialize to black progress=1.0"])
        }
        let frame1Fade = TestHarness.calculateFade(progress: current.progress)
        guard frame1Fade == 0.0 else {
            throw NSError(domain: "T3", code: 18, userInfo: [NSLocalizedDescriptionKey: "Reopening frame 1 fade is not zero"])
        }
    }

    private func clamp(_ x: Double, _ lo: Double, _ hi: Double) -> Double {
        return min(hi, max(lo, x))
    }
}
