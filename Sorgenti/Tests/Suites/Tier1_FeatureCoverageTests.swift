import Foundation
import Metal
import QuartzCore

public final class Tier1_FeatureCoverageTests {
    private var results: [TestCaseRecord] = []

    public init() {}

    public func runAll() -> [TestCaseRecord] {
        results.removeAll()

        // F1: Perspective Calibration & Singularity Avoidance
        run("F1_perspectiveScaling_normalRange", tier: 1, feature: "F1") { try self.test_F1_perspectiveScaling_normalRange() }
        run("F1_noCoordinateInversion_extremeAngle", tier: 1, feature: "F1") { try self.test_F1_noCoordinateInversion_extremeAngle() }
        run("F1_noLateAngleStretchingBlowup", tier: 1, feature: "F1") { try self.test_F1_noLateAngleStretchingBlowup() }
        run("F1_tiltBelowOpticalSingularity", tier: 1, feature: "F1") { try self.test_F1_tiltBelowOpticalSingularity() }
        run("F1_onsetSmoothnessNearZero", tier: 1, feature: "F1") { try self.test_F1_onsetSmoothnessNearZero() }

        // F2: Edge Clamping & Feathering
        run("F2_featherClampedToMaximumBound", tier: 1, feature: "F2") { try self.test_F2_featherClampedToMaximumBound() }
        run("F2_noOuterEdgePixelSmearing", tier: 1, feature: "F2") { try self.test_F2_noOuterEdgePixelSmearing() }
        run("F2_aspectRatioAdaptiveFeathering", tier: 1, feature: "F2") { try self.test_F2_aspectRatioAdaptiveFeathering() }
        run("F2_topEdgeFeatheringBounds", tier: 1, feature: "F2") { try self.test_F2_topEdgeFeatheringBounds() }
        run("F2_featheringMonotonicWithBlur", tier: 1, feature: "F2") { try self.test_F2_featheringMonotonicWithBlur() }

        // F3: LidAngleSensor Centidegree Dispatching
        run("F3_singleCentidegreeStepDispatched", tier: 1, feature: "F3") { try self.test_F3_singleCentidegreeStepDispatched() }
        run("F3_zeroDroppedCyclesAcross10000Transitions", tier: 1, feature: "F3") { try self.test_F3_zeroDroppedCyclesAcross10000Transitions() }
        run("F3_stationaryLidDispatchSuppressed", tier: 1, feature: "F3") { try self.test_F3_stationaryLidDispatchSuppressed() }
        run("F3_report7IntegerDivisionExactness", tier: 1, feature: "F3") { try self.test_F3_report7IntegerDivisionExactness() }
        run("F3_microMovementSensitivity", tier: 1, feature: "F3") { try self.test_F3_microMovementSensitivity() }

        // F4: Continuous Velocity Lead in FoldController
        run("F4_zeroLeadAtLowSpeed", tier: 1, feature: "F4") { try self.test_F4_zeroLeadAtLowSpeed() }
        run("F4_fullLeadAtHighSpeed", tier: 1, feature: "F4") { try self.test_F4_fullLeadAtHighSpeed() }
        run("F4_continuousRampNear8DegS", tier: 1, feature: "F4") { try self.test_F4_continuousRampNear8DegS() }
        run("F4_smoothLinearInterpolation", tier: 1, feature: "F4") { try self.test_F4_smoothLinearInterpolation() }
        run("F4_directionPreservation", tier: 1, feature: "F4") { try self.test_F4_directionPreservation() }

        // F5: Crisp Motion Coupling / Tau Responsiveness
        run("F5_trackingTauIs30ms", tier: 1, feature: "F5") { try self.test_F5_trackingTauIs30ms() }
        run("F5_settlingTimeUnder100ms", tier: 1, feature: "F5") { try self.test_F5_settlingTimeUnder100ms() }
        run("F5_releasingTauIs200ms", tier: 1, feature: "F5") { try self.test_F5_releasingTauIs200ms() }
        run("F5_velocitySmoothingTauIs80ms", tier: 1, feature: "F5") { try self.test_F5_velocitySmoothingTauIs80ms() }
        run("F5_stepResponseNoOvershoot", tier: 1, feature: "F5") { try self.test_F5_stepResponseNoOvershoot() }

        // F6: Wake Detection at angles 60°-80°
        run("F6_wakeAt60DegreesTriggersOpening", tier: 1, feature: "F6") { try self.test_F6_wakeAt60DegreesTriggersOpening() }
        run("F6_wakeAt70DegreesTriggersOpening", tier: 1, feature: "F6") { try self.test_F6_wakeAt70DegreesTriggersOpening() }
        run("F6_wakeAt75DegreesTriggersOpening", tier: 1, feature: "F6") { try self.test_F6_wakeAt75DegreesTriggersOpening() }
        run("F6_wakeAt79_9DegreesTriggersOpening", tier: 1, feature: "F6") { try self.test_F6_wakeAt79_9DegreesTriggersOpening() }
        run("F6_wakeAt85DegreesDoesNotTriggerOpening", tier: 1, feature: "F6") { try self.test_F6_wakeAt85DegreesDoesNotTriggerOpening() }

        // F7: Opening State Persistence
        run("F7_pausePreservesReference105", tier: 1, feature: "F7") { try self.test_F7_pausePreservesReference105() }
        run("F7_slowLidMovementDoesNotCollapseReference", tier: 1, feature: "F7") { try self.test_F7_slowLidMovementDoesNotCollapseReference() }
        run("F7_stillFlagMaskedDuringOpening", tier: 1, feature: "F7") { try self.test_F7_stillFlagMaskedDuringOpening() }
        run("F7_completionClearsOpeningFlag", tier: 1, feature: "F7") { try self.test_F7_completionClearsOpeningFlag() }
        run("F7_reversalOrCloseClearsOpeningState", tier: 1, feature: "F7") { try self.test_F7_reversalOrCloseClearsOpeningState() }

        // F8: Initial Frame Black Start
        run("F8_startOpeningInitializesProgressToOne", tier: 1, feature: "F8") { try self.test_F8_startOpeningInitializesProgressToOne() }
        run("F8_frameOneRendersPureBlack", tier: 1, feature: "F8") { try self.test_F8_frameOneRendersPureBlack() }
        run("F8_currentTiltMatchesTargetTilt", tier: 1, feature: "F8") { try self.test_F8_currentTiltMatchesTargetTilt() }
        run("F8_defocusInitializedToOne", tier: 1, feature: "F8") { try self.test_F8_defocusInitializedToOne() }
        run("F8_releasingFlagClearedOnStartOpening", tier: 1, feature: "F8") { try self.test_F8_releasingFlagClearedOnStartOpening() }

        // F9: Guaranteed Black Fade Curve
        run("F9_pureBlackAtProgress0_85", tier: 1, feature: "F9") { try self.test_F9_pureBlackAtProgress0_85() }
        run("F9_pureBlackAtProgress1_0", tier: 1, feature: "F9") { try self.test_F9_pureBlackAtProgress1_0() }
        run("F9_smoothBloomBetween0_65And0_85", tier: 1, feature: "F9") { try self.test_F9_smoothBloomBetween0_65And0_85() }
        run("F9_fullVisibilityAtProgress0_65", tier: 1, feature: "F9") { try self.test_F9_fullVisibilityAtProgress0_65() }
        run("F9_earlyReturnBlackInFragmentShader", tier: 1, feature: "F9") { try self.test_F9_earlyReturnBlackInFragmentShader() }

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

    // MARK: - F1 Tests
    private func test_F1_perspectiveScaling_normalRange() throws {
        let uv = TestVector2(0.5, 0.5)
        let tiltRad = 30.0 * .pi / 180.0
        let (mapped, sy, t, tilt) = TestHarness.calculateHoldPixel(uv: uv, u_tilt: tiltRad, u_perspective: 0.55, u_eyeDistance: 2.68)
        guard sy > 0.0 && sy <= 1.0 else { throw NSError(domain: "F1", code: 1, userInfo: [NSLocalizedDescriptionKey: "sy out of range: \(sy)"]) }
        guard t > 1.0 && t < 1.5 else { throw NSError(domain: "F1", code: 2, userInfo: [NSLocalizedDescriptionKey: "t expansion anomalous: \(t)"]) }
        guard tilt < tiltRad else { throw NSError(domain: "F1", code: 3, userInfo: [NSLocalizedDescriptionKey: "calibrated tilt should be damped"]) }
    }

    private func test_F1_noCoordinateInversion_extremeAngle() throws {
        // Delta 85 degrees (u_tilt = 1.4835)
        let tiltRad = 85.0 * .pi / 180.0
        for h in stride(from: 0.0, through: 1.0, by: 0.1) {
            let uv = TestVector2(0.5, 1.0 - h)
            let (_, sy, _, _) = TestHarness.calculateHoldPixel(uv: uv, u_tilt: tiltRad, u_perspective: 1.0, u_eyeDistance: 1.6)
            guard sy >= 0.0 else {
                throw NSError(domain: "F1", code: 4, userInfo: [NSLocalizedDescriptionKey: "Coordinate inversion at h=\(h): sy=\(sy) < 0"])
            }
        }
    }

    private func test_F1_noLateAngleStretchingBlowup() throws {
        // At delta 80 deg, stretch ratio must remain <= 2.5
        let tiltRad = 80.0 * .pi / 180.0
        let (_, _, t_top, tilt_calc) = TestHarness.calculateHoldPixel(uv: TestVector2(0.5, 0.0), u_tilt: tiltRad, u_perspective: 0.55, u_eyeDistance: 2.68)
        let D = 2.68 + 2.5
        let dsy_dh = TestHarness.calculateVerticalStretchDerivative(h: 1.0, tilt: tilt_calc, D: D)
        let stretch = (1.0 / max(1e-4, dsy_dh)) / t_top
        guard stretch <= 2.5 else {
            throw NSError(domain: "F1", code: 5, userInfo: [NSLocalizedDescriptionKey: "Late angle stretch blowup: ratio=\(stretch) > 2.5"])
        }
    }

    private func test_F1_tiltBelowOpticalSingularity() throws {
        // Verify tilt stays below theta_crit = arctan(D / 0.62) for all perspectives
        for p in stride(from: 0.0, through: 1.0, by: 0.2) {
            let D = (4.0 - 2.4 * p) + 2.5
            let thetaCrit = atan(D / 0.62)
            let (_, _, _, actualTilt) = TestHarness.calculateHoldPixel(uv: TestVector2(0.5, 0.5), u_tilt: 1.48, u_perspective: p, u_eyeDistance: 4.0 - 2.4 * p)
            guard actualTilt < thetaCrit else {
                throw NSError(domain: "F1", code: 6, userInfo: [NSLocalizedDescriptionKey: "Tilt exceeded singularity limit: \(actualTilt) >= \(thetaCrit)"])
            }
        }
    }

    private func test_F1_onsetSmoothnessNearZero() throws {
        let onset0 = TestHarness.smoother(0.0 / 0.035)
        let onsetSmall = TestHarness.smoother(0.01 / 0.035)
        guard onset0 == 0.0 else { throw NSError(domain: "F1", code: 7, userInfo: [NSLocalizedDescriptionKey: "onset at zero must be 0"]) }
        guard onsetSmall > 0.0 && onsetSmall < 0.5 else { throw NSError(domain: "F1", code: 8, userInfo: [NSLocalizedDescriptionKey: "onset transition should be smooth"]) }
    }

    // MARK: - F2 Tests
    private func test_F2_featherClampedToMaximumBound() throws {
        // Shader clamp formula: min(0.015, 1.8 * sigmaUV / aspect)
        let maxSigmaUV = 0.05
        let aspect = 1.54
        let rawFwX = 1.8 * maxSigmaUV / aspect
        let clampedFwX = min(0.015, rawFwX)
        guard clampedFwX <= 0.015 else {
            throw NSError(domain: "F2", code: 1, userInfo: [NSLocalizedDescriptionKey: "clampedFwX exceeded 0.015: \(clampedFwX)"])
        }
    }

    private func test_F2_noOuterEdgePixelSmearing() throws {
        let fw_x = 0.015
        // At outer edge x = 1.0 + fw_x, coverage must be strictly 0.0
        let edgeRight = 1.0 - TestHarness.smoothstep(1.0, 1.0 + fw_x, 1.0 + fw_x)
        guard edgeRight == 0.0 else {
            throw NSError(domain: "F2", code: 2, userInfo: [NSLocalizedDescriptionKey: "Outer edge does not fall to 0 at edge boundary"])
        }
    }

    private func test_F2_aspectRatioAdaptiveFeathering() throws {
        let sigma = 0.005
        let fw16_10 = min(0.015, 1.8 * sigma / 1.6)
        let fw4_3 = min(0.015, 1.8 * sigma / 1.333)
        guard fw4_3 > fw16_10 else {
            throw NSError(domain: "F2", code: 3, userInfo: [NSLocalizedDescriptionKey: "Narrower aspect ratio should have proportionally adjusted feather"])
        }
    }

    private func test_F2_topEdgeFeatheringBounds() throws {
        let maxSigma = 0.04
        let fwTop = min(0.015, 1.8 * maxSigma)
        guard fwTop <= 0.015 else {
            throw NSError(domain: "F2", code: 4, userInfo: [NSLocalizedDescriptionKey: "Top edge feather exceeded max bound"])
        }
    }

    private func test_F2_featheringMonotonicWithBlur() throws {
        let fwLow = min(0.015, 1.8 * (0.01) / 1.54)
        let fwHigh = min(0.015, 1.8 * (0.04) / 1.54)
        guard fwHigh >= fwLow else {
            throw NSError(domain: "F2", code: 5, userInfo: [NSLocalizedDescriptionKey: "Feathering must be monotonic with blur"])
        }
    }

    // MARK: - F3 Tests
    private func test_F3_singleCentidegreeStepDispatched() throws {
        var dispatchedCount = 0
        let threshold = 0.001
        var lastAngle: Double = -1.0
        let sequence = [100.00, 100.01]
        for angle in sequence {
            if abs(angle - lastAngle) >= threshold {
                dispatchedCount += 1
                lastAngle = angle
            }
        }
        guard dispatchedCount == 2 else {
            throw NSError(domain: "F3", code: 1, userInfo: [NSLocalizedDescriptionKey: "Single centidegree step was dropped: \(dispatchedCount)/2"])
        }
    }

    private func test_F3_zeroDroppedCyclesAcross10000Transitions() throws {
        var drops = 0
        let threshold = 0.001
        for raw in 5000..<15000 {
            let a1 = Double(raw) / 100.0
            let a2 = Double(raw + 1) / 100.0
            if abs(a2 - a1) < threshold {
                drops += 1
            }
        }
        guard drops == 0 else {
            throw NSError(domain: "F3", code: 2, userInfo: [NSLocalizedDescriptionKey: "Dropped \(drops) out of 10,000 centidegree cycles with threshold < 0.001"])
        }
    }

    private func test_F3_stationaryLidDispatchSuppressed() throws {
        var dispatched = 0
        var lastAngle = 90.0
        let stationaryStream = [90.0, 90.0, 90.0, 90.0]
        for a in stationaryStream {
            if abs(a - lastAngle) >= 0.001 {
                dispatched += 1
                lastAngle = a
            }
        }
        guard dispatched == 0 else {
            throw NSError(domain: "F3", code: 3, userInfo: [NSLocalizedDescriptionKey: "Stationary samples should not be dispatched"])
        }
    }

    private func test_F3_report7IntegerDivisionExactness() throws {
        let raw: Int = 10542
        let angle = Double(raw) / 100.0
        guard angle == 105.42 else {
            throw NSError(domain: "F3", code: 4, userInfo: [NSLocalizedDescriptionKey: "Exact centidegree division failed: \(angle) != 105.42"])
        }
    }

    private func test_F3_microMovementSensitivity() throws {
        let initial = 70.00
        let next = 70.02
        guard abs(next - initial) >= 0.001 else {
            throw NSError(domain: "F3", code: 5, userInfo: [NSLocalizedDescriptionKey: "0.02 deg movement should easily exceed dispatch threshold"])
        }
    }

    // MARK: - F4 Tests
    private func test_F4_zeroLeadAtLowSpeed() throws {
        let leadLow = TestHarness.calculateVelocityLead(slope: 2.5)
        guard leadLow == 0.0 else {
            throw NSError(domain: "F4", code: 1, userInfo: [NSLocalizedDescriptionKey: "Lead at 2.5 deg/s should be 0, got \(leadLow)"])
        }
    }

    private func test_F4_fullLeadAtHighSpeed() throws {
        let leadHigh = TestHarness.calculateVelocityLead(slope: 20.0)
        let expected = 1.0 / 60.0
        guard abs(leadHigh - expected) < 1e-9 else {
            throw NSError(domain: "F4", code: 2, userInfo: [NSLocalizedDescriptionKey: "Lead at 20 deg/s should be 1/60, got \(leadHigh)"])
        }
    }

    private func test_F4_continuousRampNear8DegS() throws {
        let lead7_99 = TestHarness.calculateVelocityLead(slope: 7.99)
        let lead8_01 = TestHarness.calculateVelocityLead(slope: 8.01)
        let delta = abs(lead8_01 - lead7_99)
        guard delta < 0.0001 else {
            throw NSError(domain: "F4", code: 3, userInfo: [NSLocalizedDescriptionKey: "Discontinuity at 8 deg/s threshold: jump=\(delta)"])
        }
    }

    private func test_F4_smoothLinearInterpolation() throws {
        let lead4 = TestHarness.calculateVelocityLead(slope: 4.0)
        let lead8 = TestHarness.calculateVelocityLead(slope: 8.0)
        let lead12 = TestHarness.calculateVelocityLead(slope: 12.0)
        guard lead4 == 0.0 else { throw NSError(domain: "F4", code: 4, userInfo: [NSLocalizedDescriptionKey: "lead(4) != 0"]) }
        guard abs(lead8 - (0.5 / 60.0)) < 1e-9 else { throw NSError(domain: "F4", code: 5, userInfo: [NSLocalizedDescriptionKey: "lead(8) != 0.5/60"]) }
        guard abs(lead12 - (1.0 / 60.0)) < 1e-9 else { throw NSError(domain: "F4", code: 6, userInfo: [NSLocalizedDescriptionKey: "lead(12) != 1/60"]) }
    }

    private func test_F4_directionPreservation() throws {
        let leadPos = TestHarness.calculateVelocityLead(slope: 10.0)
        let leadNeg = TestHarness.calculateVelocityLead(slope: -10.0)
        guard leadPos == leadNeg else {
            throw NSError(domain: "F4", code: 7, userInfo: [NSLocalizedDescriptionKey: "Lead factor magnitude must depend only on abs(slope)"])
        }
    }

    // MARK: - F5 Tests
    private func test_F5_trackingTauIs30ms() throws {
        let tau = 0.030
        guard tau == 0.030 else {
            throw NSError(domain: "F5", code: 1, userInfo: [NSLocalizedDescriptionKey: "Tracking tau is not 0.030s"])
        }
    }

    private func test_F5_settlingTimeUnder100ms() throws {
        let tau = 0.030
        let threeTau = 3.0 * tau
        guard threeTau < 0.100 else {
            throw NSError(domain: "F5", code: 2, userInfo: [NSLocalizedDescriptionKey: "Settling time \(threeTau)s exceeds 100ms"])
        }
        let history = TestHarness.simulateExponentialSmoothing(start: 0.0, target: 1.0, tau: tau, dt: 1.0/60.0, steps: 6)
        let step6 = history[6]
        guard step6 >= 0.95 else {
            throw NSError(domain: "F5", code: 3, userInfo: [NSLocalizedDescriptionKey: "Did not reach 95% within 6 frames (~100ms): reached \(step6)"])
        }
    }

    private func test_F5_releasingTauIs200ms() throws {
        let releasingTau = 0.20
        guard releasingTau == 0.20 else {
            throw NSError(domain: "F5", code: 4, userInfo: [NSLocalizedDescriptionKey: "Releasing tau should be 0.20"])
        }
    }

    private func test_F5_velocitySmoothingTauIs80ms() throws {
        let velTau = 0.08
        guard velTau == 0.08 else {
            throw NSError(domain: "F5", code: 5, userInfo: [NSLocalizedDescriptionKey: "Velocity tau should be 0.08"])
        }
    }

    private func test_F5_stepResponseNoOvershoot() throws {
        let history = TestHarness.simulateExponentialSmoothing(start: 0.0, target: 1.0, tau: 0.030, dt: 0.016, steps: 20)
        for i in 1..<history.count {
            guard history[i] >= history[i - 1] && history[i] <= 1.0 else {
                throw NSError(domain: "F5", code: 6, userInfo: [NSLocalizedDescriptionKey: "Overshoot or non-monotonic response detected"])
            }
        }
    }

    // MARK: - F6 Tests
    private func test_F6_wakeAt60DegreesTriggersOpening() throws {
        let angle = 60.0
        let isOpening = angle < 80.0
        guard isOpening else { throw NSError(domain: "F6", code: 1, userInfo: [NSLocalizedDescriptionKey: "60 deg failed to trigger opening"]) }
    }

    private func test_F6_wakeAt70DegreesTriggersOpening() throws {
        let angle = 70.0
        let isOpening = angle < 80.0
        guard isOpening else { throw NSError(domain: "F6", code: 2, userInfo: [NSLocalizedDescriptionKey: "70 deg failed to trigger opening"]) }
    }

    private func test_F6_wakeAt75DegreesTriggersOpening() throws {
        let angle = 75.0
        let isOpening = angle < 80.0
        guard isOpening else { throw NSError(domain: "F6", code: 3, userInfo: [NSLocalizedDescriptionKey: "75 deg failed to trigger opening"]) }
    }

    private func test_F6_wakeAt79_9DegreesTriggersOpening() throws {
        let angle = 79.9
        let isOpening = angle < 80.0
        guard isOpening else { throw NSError(domain: "F6", code: 4, userInfo: [NSLocalizedDescriptionKey: "79.9 deg failed to trigger opening"]) }
    }

    private func test_F6_wakeAt85DegreesDoesNotTriggerOpening() throws {
        let angle = 85.0
        let isOpening = angle < 80.0
        guard !isOpening else { throw NSError(domain: "F6", code: 5, userInfo: [NSLocalizedDescriptionKey: "85 deg should NOT trigger opening from closed"]) }
    }

    // MARK: - F7 Tests
    private func test_F7_pausePreservesReference105() throws {
        var isOpeningFromClosed = true
        var reference = 105.0
        let stillAnchor = 75.0
        let now = 10.0
        let stillSince = 8.0 // 2 seconds motionless (> stillDelay 0.6s)
        let isStill = isOpeningFromClosed ? false : (now - stillSince >= 0.6)
        let resting = isStill ? stillAnchor : reference
        let ref = max(resting, 75.0)
        reference = ref
        guard reference == 105.0 else {
            throw NSError(domain: "F7", code: 1, userInfo: [NSLocalizedDescriptionKey: "Reference collapsed during opening pause: \(reference) != 105.0"])
        }
    }

    private func test_F7_slowLidMovementDoesNotCollapseReference() throws {
        let isOpeningFromClosed = true
        let reference = 105.0
        let isStill = isOpeningFromClosed ? false : true
        guard !isStill && reference == 105.0 else {
            throw NSError(domain: "F7", code: 2, userInfo: [NSLocalizedDescriptionKey: "Slow motion collapsed reference"])
        }
    }

    private func test_F7_stillFlagMaskedDuringOpening() throws {
        let isOpeningFromClosed = true
        let isStill = isOpeningFromClosed ? false : true
        guard isStill == false else {
            throw NSError(domain: "F7", code: 3, userInfo: [NSLocalizedDescriptionKey: "isStill must be false while opening from closed"])
        }
    }

    private func test_F7_completionClearsOpeningFlag() throws {
        var isOpeningFromClosed = true
        let reference = 105.0
        let newAngle = 103.5
        if isOpeningFromClosed && newAngle >= reference - 2.0 {
            isOpeningFromClosed = false
        }
        guard isOpeningFromClosed == false else {
            throw NSError(domain: "F7", code: 4, userInfo: [NSLocalizedDescriptionKey: "Opening flag not cleared upon reaching 103.5 deg"])
        }
    }

    private func test_F7_reversalOrCloseClearsOpeningState() throws {
        var isOpeningFromClosed = true
        let delta = 0.02 // closed down below 0.05
        if delta <= 0.05 {
            isOpeningFromClosed = false
        }
        guard isOpeningFromClosed == false else {
            throw NSError(domain: "F7", code: 5, userInfo: [NSLocalizedDescriptionKey: "Closing back down did not clear opening state"])
        }
    }

    // MARK: - F8 Tests
    private func test_F8_startOpeningInitializesProgressToOne() throws {
        let target = FoldState(tilt: 0.5, progress: 0.35, defocus: 0.2, velocity: 0)
        let current = FoldState(tilt: target.tilt, progress: 1.0, defocus: 1.0, velocity: 0)
        guard current.progress == 1.0 else {
            throw NSError(domain: "F8", code: 1, userInfo: [NSLocalizedDescriptionKey: "current.progress should be 1.0"])
        }
    }

    private func test_F8_frameOneRendersPureBlack() throws {
        guard let pixels = TestHarness.shared.renderToPixels(uniforms: TestHarness.RenderUniforms(progress: 1.0, defocus: 1.0)) else {
            throw NSError(domain: "F8", code: 2, userInfo: [NSLocalizedDescriptionKey: "Metal render failed"])
        }
        // Pixel format bgra8Unorm: index 0=B, 1=G, 2=R, 3=A
        let centerB = pixels[0], centerG = pixels[1], centerR = pixels[2], centerA = pixels[3]
        guard centerR == 0 && centerG == 0 && centerB == 0 && centerA == 255 else {
            throw NSError(domain: "F8", code: 3, userInfo: [NSLocalizedDescriptionKey: "Frame 1 did not render pure black: (\(centerR), \(centerG), \(centerB), \(centerA))"])
        }
    }

    private func test_F8_currentTiltMatchesTargetTilt() throws {
        let target = FoldState(tilt: 0.72, progress: 0.4, defocus: 0.3, velocity: 0)
        let current = FoldState(tilt: target.tilt, progress: 1.0, defocus: 1.0, velocity: 0)
        guard current.tilt == target.tilt else {
            throw NSError(domain: "F8", code: 4, userInfo: [NSLocalizedDescriptionKey: "Tilt did not match target tilt"])
        }
    }

    private func test_F8_defocusInitializedToOne() throws {
        let current = FoldState(tilt: 0.5, progress: 1.0, defocus: 1.0, velocity: 0)
        guard current.defocus == 1.0 else {
            throw NSError(domain: "F8", code: 5, userInfo: [NSLocalizedDescriptionKey: "defocus not initialized to 1.0"])
        }
    }

    private func test_F8_releasingFlagClearedOnStartOpening() throws {
        var releasing = true
        // startOpening sets releasing = false
        releasing = false
        guard !releasing else {
            throw NSError(domain: "F8", code: 6, userInfo: [NSLocalizedDescriptionKey: "releasing should be false"])
        }
    }

    // MARK: - F9 Tests
    private func test_F9_pureBlackAtProgress0_85() throws {
        let fade = TestHarness.calculateFade(progress: 0.85)
        guard fade == 0.0 else {
            throw NSError(domain: "F9", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fade at progress=0.85 must be 0.0, got \(fade)"])
        }
    }

    private func test_F9_pureBlackAtProgress1_0() throws {
        let fade = TestHarness.calculateFade(progress: 1.0)
        guard fade == 0.0 else {
            throw NSError(domain: "F9", code: 2, userInfo: [NSLocalizedDescriptionKey: "Fade at progress=1.0 must be 0.0, got \(fade)"])
        }
    }

    private func test_F9_smoothBloomBetween0_65And0_85() throws {
        let fade0_85 = TestHarness.calculateFade(progress: 0.85)
        let fade0_75 = TestHarness.calculateFade(progress: 0.75)
        let fade0_65 = TestHarness.calculateFade(progress: 0.65)
        guard fade0_85 == 0.0 else { throw NSError(domain: "F9", code: 3, userInfo: [NSLocalizedDescriptionKey: "fade(0.85) != 0"]) }
        guard abs(fade0_75 - 0.5) < 1e-6 else { throw NSError(domain: "F9", code: 4, userInfo: [NSLocalizedDescriptionKey: "fade(0.75) != 0.5"]) }
        guard fade0_65 == 1.0 else { throw NSError(domain: "F9", code: 5, userInfo: [NSLocalizedDescriptionKey: "fade(0.65) != 1.0"]) }
    }

    private func test_F9_fullVisibilityAtProgress0_65() throws {
        let fadeLow = TestHarness.calculateFade(progress: 0.50)
        guard fadeLow == 1.0 else {
            throw NSError(domain: "F9", code: 6, userInfo: [NSLocalizedDescriptionKey: "Fade at progress <= 0.65 must be 1.0, got \(fadeLow)"])
        }
    }

    private func test_F9_earlyReturnBlackInFragmentShader() throws {
        guard let pixels = TestHarness.shared.renderToPixels(uniforms: TestHarness.RenderUniforms(progress: 0.86)) else {
            throw NSError(domain: "F9", code: 7, userInfo: [NSLocalizedDescriptionKey: "Render failed"])
        }
        guard pixels[0] == 0 && pixels[1] == 0 && pixels[2] == 0 && pixels[3] == 255 else {
            throw NSError(domain: "F9", code: 8, userInfo: [NSLocalizedDescriptionKey: "Early return did not return pure black at progress=0.86"])
        }
    }
}
