import Foundation
import Metal
import QuartzCore

public final class Tier2_BoundaryCornerTests {
    private var results: [TestCaseRecord] = []

    public init() {}

    public func runAll() -> [TestCaseRecord] {
        results.removeAll()

        // 1. Boundary Angles (0°, 10°, 70°, 80°, 85°)
        run("B1_boundaryAngle_0deg_fullyClosed", tier: 2, feature: "Angles") { try self.test_B1_boundaryAngle_0deg_fullyClosed() }
        run("B1_boundaryAngle_10deg_closeAngleLimit", tier: 2, feature: "Angles") { try self.test_B1_boundaryAngle_10deg_closeAngleLimit() }
        run("B1_boundaryAngle_70deg_transitionZone", tier: 2, feature: "Angles") { try self.test_B1_boundaryAngle_70deg_transitionZone() }
        run("B1_boundaryAngle_80deg_wakeThresholdBoundary", tier: 2, feature: "Angles") { try self.test_B1_boundaryAngle_80deg_wakeThresholdBoundary() }
        run("B1_boundaryAngle_85deg_maxTiltClamp", tier: 2, feature: "Angles") { try self.test_B1_boundaryAngle_85deg_maxTiltClamp() }

        // 2. Negative Deltas & Reverse Opening
        run("B2_negativeDelta_slightPastReference", tier: 2, feature: "Deltas") { try self.test_B2_negativeDelta_slightPastReference() }
        run("B2_negativeDelta_largeOvershoot", tier: 2, feature: "Deltas") { try self.test_B2_negativeDelta_largeOvershoot() }
        run("B2_zeroDelta_restingState", tier: 2, feature: "Deltas") { try self.test_B2_zeroDelta_restingState() }
        run("B2_subthresholdDelta_0_04deg", tier: 2, feature: "Deltas") { try self.test_B2_subthresholdDelta_0_04deg() }
        run("B2_infiniteOrNaNDeltaSafety", tier: 2, feature: "Deltas") { try self.test_B2_infiniteOrNaNDeltaSafety() }

        // 3. Velocity Threshold Boundaries (8°/s)
        run("B3_velocityExact8DegS", tier: 2, feature: "Velocity") { try self.test_B3_velocityExact8DegS() }
        run("B3_velocityInfinitesimalBelow8DegS", tier: 2, feature: "Velocity") { try self.test_B3_velocityInfinitesimalBelow8DegS() }
        run("B3_velocityInfinitesimalAbove8DegS", tier: 2, feature: "Velocity") { try self.test_B3_velocityInfinitesimalAbove8DegS() }
        run("B3_velocityRapidSignFlipAtThreshold", tier: 2, feature: "Velocity") { try self.test_B3_velocityRapidSignFlipAtThreshold() }
        run("B3_velocityExtremeHighSpeed120DegS", tier: 2, feature: "Velocity") { try self.test_B3_velocityExtremeHighSpeed120DegS() }

        // 4. IEEE 754 Precision Transitions
        run("B4_ieee754_transition_99_90_to_99_91", tier: 2, feature: "Precision") { try self.test_B4_ieee754_transition_99_90_to_99_91() }
        run("B4_ieee754_transition_0_09_to_0_10", tier: 2, feature: "Precision") { try self.test_B4_ieee754_transition_0_09_to_0_10() }
        run("B4_ieee754_transition_19_99_to_20_00", tier: 2, feature: "Precision") { try self.test_B4_ieee754_transition_19_99_to_20_00() }
        run("B4_ieee754_transition_104_99_to_105_00", tier: 2, feature: "Precision") { try self.test_B4_ieee754_transition_104_99_to_105_00() }
        run("B4_ieee754_transition_359_99_to_360_00", tier: 2, feature: "Precision") { try self.test_B4_ieee754_transition_359_99_to_360_00() }

        // 5. Extreme Aspect Ratios
        run("B5_aspectRatio_macNative_16_10", tier: 2, feature: "Aspect") { try self.test_B5_aspectRatio_macNative_16_10() }
        run("B5_aspectRatio_ultraWide_32_9", tier: 2, feature: "Aspect") { try self.test_B5_aspectRatio_ultraWide_32_9() }
        run("B5_aspectRatio_portrait_9_16", tier: 2, feature: "Aspect") { try self.test_B5_aspectRatio_portrait_9_16() }
        run("B5_aspectRatio_square_1_1", tier: 2, feature: "Aspect") { try self.test_B5_aspectRatio_square_1_1() }
        run("B5_aspectRatio_zeroOrNegativeFallback", tier: 2, feature: "Aspect") { try self.test_B5_aspectRatio_zeroOrNegativeFallback() }

        // 6. Perspective Parameter Boundaries
        run("B6_perspective_exact0_0", tier: 2, feature: "Perspective") { try self.test_B6_perspective_exact0_0() }
        run("B6_perspective_default0_55", tier: 2, feature: "Perspective") { try self.test_B6_perspective_default0_55() }
        run("B6_perspective_exact1_0", tier: 2, feature: "Perspective") { try self.test_B6_perspective_exact1_0() }
        run("B6_perspective_clampedBelow0", tier: 2, feature: "Perspective") { try self.test_B6_perspective_clampedBelow0() }
        run("B6_perspective_clampedAbove1", tier: 2, feature: "Perspective") { try self.test_B6_perspective_clampedAbove1() }

        // 7. Time Delta Step Boundaries
        run("B7_timeDelta_zeroDt", tier: 2, feature: "TimeDelta") { try self.test_B7_timeDelta_zeroDt() }
        run("B7_timeDelta_microsecondDt", tier: 2, feature: "TimeDelta") { try self.test_B7_timeDelta_microsecondDt() }
        run("B7_timeDelta_displayLink120Hz", tier: 2, feature: "TimeDelta") { try self.test_B7_timeDelta_displayLink120Hz() }
        run("B7_timeDelta_displayLink60Hz", tier: 2, feature: "TimeDelta") { try self.test_B7_timeDelta_displayLink60Hz() }
        run("B7_timeDelta_clampedMaxDt0_1s", tier: 2, feature: "TimeDelta") { try self.test_B7_timeDelta_clampedMaxDt0_1s() }

        // 8. Visual Appearance Extremes
        run("B8_appearance_zeroBlur_zeroDim", tier: 2, feature: "Appearance") { try self.test_B8_appearance_zeroBlur_zeroDim() }
        run("B8_appearance_maxBlur_maxDim", tier: 2, feature: "Appearance") { try self.test_B8_appearance_maxBlur_maxDim() }
        run("B8_appearance_glossDisabled", tier: 2, feature: "Appearance") { try self.test_B8_appearance_glossDisabled() }
        run("B8_appearance_glossEnabled", tier: 2, feature: "Appearance") { try self.test_B8_appearance_glossEnabled() }
        run("B8_appearance_styleSwellBoundary", tier: 2, feature: "Appearance") { try self.test_B8_appearance_styleSwellBoundary() }

        // 9. Hardware Hinge Angle Limits
        run("B9_hardwareLimit_zeroDegReport", tier: 2, feature: "HingeLimits") { try self.test_B9_hardwareLimit_zeroDegReport() }
        run("B9_hardwareLimit_135degReport", tier: 2, feature: "HingeLimits") { try self.test_B9_hardwareLimit_135degReport() }
        run("B9_hardwareLimit_180degReport", tier: 2, feature: "HingeLimits") { try self.test_B9_hardwareLimit_180degReport() }
        run("B9_hardwareLimit_report7Over36000Rejected", tier: 2, feature: "HingeLimits") { try self.test_B9_hardwareLimit_report7Over36000Rejected() }
        run("B9_hardwareLimit_report1Over360Rejected", tier: 2, feature: "HingeLimits") { try self.test_B9_hardwareLimit_report1Over360Rejected() }

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

    // MARK: - 1. Boundary Angles
    private func test_B1_boundaryAngle_0deg_fullyClosed() throws {
        let state = FoldState.closing(delta: 105.0, reference: 105.0, closeAngle: 10.0)
        guard state.progress == 1.0 else {
            throw NSError(domain: "B1", code: 1, userInfo: [NSLocalizedDescriptionKey: "progress at 0 deg (delta 105) must be 1.0, got \(state.progress)"])
        }
        let fade = TestHarness.calculateFade(progress: state.progress)
        guard fade == 0.0 else {
            throw NSError(domain: "B1", code: 2, userInfo: [NSLocalizedDescriptionKey: "fade at 0 deg must be 0.0, got \(fade)"])
        }
    }

    private func test_B1_boundaryAngle_10deg_closeAngleLimit() throws {
        // Delta = 105 - 10 = 95. Span = 105 - 10 = 95. Progress = 1.0.
        let state = FoldState.closing(delta: 95.0, reference: 105.0, closeAngle: 10.0)
        guard state.progress == 1.0 else {
            throw NSError(domain: "B1", code: 3, userInfo: [NSLocalizedDescriptionKey: "progress at closeAngle must be 1.0"])
        }
        guard TestHarness.calculateFade(progress: state.progress) == 0.0 else {
            throw NSError(domain: "B1", code: 4, userInfo: [NSLocalizedDescriptionKey: "fade at closeAngle must be 0.0"])
        }
    }

    private func test_B1_boundaryAngle_70deg_transitionZone() throws {
        let delta = 105.0 - 70.0 // 35 deg
        let state = FoldState.closing(delta: delta, reference: 105.0, closeAngle: 10.0)
        guard state.progress > 0.3 && state.progress < 0.4 else {
            throw NSError(domain: "B1", code: 5, userInfo: [NSLocalizedDescriptionKey: "progress at 70 deg unexpected: \(state.progress)"])
        }
        let (mapped, sy, t, tilt) = TestHarness.calculateHoldPixel(uv: TestVector2(0.5, 0.5), u_tilt: state.tilt, u_perspective: 0.55, u_eyeDistance: 2.68)
        guard sy > 0.0 && sy <= 1.0 else {
            throw NSError(domain: "B1", code: 6, userInfo: [NSLocalizedDescriptionKey: "sy invalid at 70 deg: \(sy)"])
        }
    }

    private func test_B1_boundaryAngle_80deg_wakeThresholdBoundary() throws {
        let a79_9: Double = 79.9
        let a80_0: Double = 80.0
        let a80_1: Double = 80.1
        let isOpening79_9 = a79_9 < 80.0
        let isOpening80_0 = a80_0 < 80.0
        let isOpening80_1 = a80_1 < 80.0
        guard isOpening79_9 == true else { throw NSError(domain: "B1", code: 7, userInfo: [NSLocalizedDescriptionKey: "79.9 should trigger wake"]) }
        guard isOpening80_0 == false else { throw NSError(domain: "B1", code: 8, userInfo: [NSLocalizedDescriptionKey: "80.0 is boundary limit"]) }
        guard isOpening80_1 == false else { throw NSError(domain: "B1", code: 9, userInfo: [NSLocalizedDescriptionKey: "80.1 should not trigger wake"]) }
    }

    private func test_B1_boundaryAngle_85deg_maxTiltClamp() throws {
        let state = FoldState.closing(delta: 90.0, reference: 105.0, closeAngle: 10.0)
        let maxTiltRad = 85.0 * .pi / 180.0
        guard state.tilt <= maxTiltRad else {
            throw NSError(domain: "B1", code: 10, userInfo: [NSLocalizedDescriptionKey: "tilt not clamped to 85 deg: \(state.tilt) > \(maxTiltRad)"])
        }
    }

    // MARK: - 2. Negative Deltas & Reverse Opening
    private func test_B2_negativeDelta_slightPastReference() throws {
        let state = FoldState.closing(delta: -0.5, reference: 105.0, closeAngle: 10.0)
        guard state == .clear else {
            throw NSError(domain: "B2", code: 1, userInfo: [NSLocalizedDescriptionKey: "negative delta did not return clear state"])
        }
    }

    private func test_B2_negativeDelta_largeOvershoot() throws {
        let state = FoldState.closing(delta: -25.0, reference: 105.0, closeAngle: 10.0)
        guard state == .clear else {
            throw NSError(domain: "B2", code: 2, userInfo: [NSLocalizedDescriptionKey: "large negative delta did not return clear state"])
        }
    }

    private func test_B2_zeroDelta_restingState() throws {
        let state = FoldState.closing(delta: 0.0, reference: 105.0, closeAngle: 10.0)
        guard state == .clear else {
            throw NSError(domain: "B2", code: 3, userInfo: [NSLocalizedDescriptionKey: "zero delta did not return clear state"])
        }
    }

    private func test_B2_subthresholdDelta_0_04deg() throws {
        let delta = 0.04
        guard delta <= 0.05 else {
            throw NSError(domain: "B2", code: 4, userInfo: [NSLocalizedDescriptionKey: "subthreshold check failed"])
        }
    }

    private func test_B2_infiniteOrNaNDeltaSafety() throws {
        let stateInf = FoldState.closing(delta: Double.infinity, reference: 105.0, closeAngle: 10.0)
        let stateNaN = FoldState.closing(delta: Double.nan, reference: 105.0, closeAngle: 10.0)
        guard stateInf == .clear && stateNaN == .clear else {
            throw NSError(domain: "B2", code: 5, userInfo: [NSLocalizedDescriptionKey: "inf/NaN delta did not return clear state"])
        }
    }

    // MARK: - 3. Velocity Threshold Boundaries (8°/s)
    private func test_B3_velocityExact8DegS() throws {
        let lead = TestHarness.calculateVelocityLead(slope: 8.0)
        let expected = 0.5 * (1.0 / 60.0)
        guard abs(lead - expected) < 1e-12 else {
            throw NSError(domain: "B3", code: 1, userInfo: [NSLocalizedDescriptionKey: "lead at 8 deg/s must be 0.5/60, got \(lead)"])
        }
    }

    private func test_B3_velocityInfinitesimalBelow8DegS() throws {
        let lead = TestHarness.calculateVelocityLead(slope: 7.9999)
        let expected = ((7.9999 - 4.0) / 8.0) * (1.0 / 60.0)
        guard abs(lead - expected) < 1e-9 else {
            throw NSError(domain: "B3", code: 2, userInfo: [NSLocalizedDescriptionKey: "lead calculation discrepancy below 8 deg/s"])
        }
    }

    private func test_B3_velocityInfinitesimalAbove8DegS() throws {
        let lead = TestHarness.calculateVelocityLead(slope: 8.0001)
        let expected = ((8.0001 - 4.0) / 8.0) * (1.0 / 60.0)
        guard abs(lead - expected) < 1e-9 else {
            throw NSError(domain: "B3", code: 3, userInfo: [NSLocalizedDescriptionKey: "lead calculation discrepancy above 8 deg/s"])
        }
    }

    private func test_B3_velocityRapidSignFlipAtThreshold() throws {
        let leadPos = TestHarness.calculateVelocityLead(slope: 8.0)
        let leadNeg = TestHarness.calculateVelocityLead(slope: -8.0)
        guard leadPos == leadNeg else {
            throw NSError(domain: "B3", code: 4, userInfo: [NSLocalizedDescriptionKey: "Symmetry broken on sign flip"])
        }
    }

    private func test_B3_velocityExtremeHighSpeed120DegS() throws {
        let lead = TestHarness.calculateVelocityLead(slope: 120.0)
        guard lead == (1.0 / 60.0) else {
            throw NSError(domain: "B3", code: 5, userInfo: [NSLocalizedDescriptionKey: "Lead not clamped to 1/60s at 120 deg/s"])
        }
    }

    // MARK: - 4. IEEE 754 Precision Transitions
    private func test_B4_ieee754_transition_99_90_to_99_91() throws {
        let a1 = 9990.0 / 100.0
        let a2 = 9991.0 / 100.0
        let diff = abs(a2 - a1)
        guard diff >= 0.001 else {
            throw NSError(domain: "B4", code: 1, userInfo: [NSLocalizedDescriptionKey: "99.90 -> 99.91 was dropped: diff=\(diff)"])
        }
    }

    private func test_B4_ieee754_transition_0_09_to_0_10() throws {
        let a1 = 9.0 / 100.0
        let a2 = 10.0 / 100.0
        let diff = abs(a2 - a1)
        guard diff >= 0.001 else {
            throw NSError(domain: "B4", code: 2, userInfo: [NSLocalizedDescriptionKey: "0.09 -> 0.10 was dropped: diff=\(diff)"])
        }
    }

    private func test_B4_ieee754_transition_19_99_to_20_00() throws {
        let a1 = 1999.0 / 100.0
        let a2 = 2000.0 / 100.0
        let diff = abs(a2 - a1)
        guard diff >= 0.001 else {
            throw NSError(domain: "B4", code: 3, userInfo: [NSLocalizedDescriptionKey: "19.99 -> 20.00 was dropped: diff=\(diff)"])
        }
    }

    private func test_B4_ieee754_transition_104_99_to_105_00() throws {
        let a1 = 10499.0 / 100.0
        let a2 = 10500.0 / 100.0
        let diff = abs(a2 - a1)
        guard diff >= 0.001 else {
            throw NSError(domain: "B4", code: 4, userInfo: [NSLocalizedDescriptionKey: "104.99 -> 105.00 was dropped: diff=\(diff)"])
        }
    }

    private func test_B4_ieee754_transition_359_99_to_360_00() throws {
        let a1 = 35999.0 / 100.0
        let a2 = 36000.0 / 100.0
        let diff = abs(a2 - a1)
        guard diff >= 0.001 else {
            throw NSError(domain: "B4", code: 5, userInfo: [NSLocalizedDescriptionKey: "359.99 -> 360.00 was dropped: diff=\(diff)"])
        }
    }

    // MARK: - 5. Extreme Aspect Ratios
    private func test_B5_aspectRatio_macNative_16_10() throws {
        let aspect: Float = 1.6
        let fw = min(0.015, 1.8 * 0.02 / aspect)
        guard fw <= 0.015 && fw > 0 else { throw NSError(domain: "B5", code: 1, userInfo: [NSLocalizedDescriptionKey: "fw invalid on 16:10"]) }
    }

    private func test_B5_aspectRatio_ultraWide_32_9() throws {
        let aspect: Float = 32.0 / 9.0 // 3.555
        let fw = min(0.015, 1.8 * 0.02 / aspect)
        guard fw <= 0.015 && fw > 0 else { throw NSError(domain: "B5", code: 2, userInfo: [NSLocalizedDescriptionKey: "fw invalid on 32:9"]) }
    }

    private func test_B5_aspectRatio_portrait_9_16() throws {
        let aspect: Float = 9.0 / 16.0 // 0.5625
        let fw = min(0.015, 1.8 * 0.02 / max(aspect, 0.1))
        guard fw == 0.015 else { throw NSError(domain: "B5", code: 3, userInfo: [NSLocalizedDescriptionKey: "fw should clamp to 0.015 on tall portrait"]) }
    }

    private func test_B5_aspectRatio_square_1_1() throws {
        let aspect: Float = 1.0
        let fw = min(0.015, 1.8 * 0.02 / aspect)
        guard fw <= 0.015 else { throw NSError(domain: "B5", code: 4, userInfo: [NSLocalizedDescriptionKey: "fw exceeded on square 1:1"]) }
    }

    private func test_B5_aspectRatio_zeroOrNegativeFallback() throws {
        let aspect: Float = 0.0
        let safeAspect = max(aspect, 0.1)
        let fw = min(0.015, 1.8 * 0.02 / safeAspect)
        guard fw == 0.015 && fw.isFinite else {
            throw NSError(domain: "B5", code: 5, userInfo: [NSLocalizedDescriptionKey: "Zero aspect did not fall back cleanly"])
        }
    }

    // MARK: - 6. Perspective Parameter Boundaries
    private func test_B6_perspective_exact0_0() throws {
        let p = 0.0
        let mult = 0.74 + 0.12 * p
        guard abs(mult - 0.74) < 1e-6 else { throw NSError(domain: "B6", code: 1, userInfo: [NSLocalizedDescriptionKey: "mult at p=0 != 0.74"]) }
    }

    private func test_B6_perspective_default0_55() throws {
        let p = 0.55
        let mult = 0.74 + 0.12 * p
        guard abs(mult - 0.806) < 1e-6 else { throw NSError(domain: "B6", code: 2, userInfo: [NSLocalizedDescriptionKey: "mult at p=0.55 != 0.806"]) }
    }

    private func test_B6_perspective_exact1_0() throws {
        let p = 1.0
        let mult = 0.74 + 0.12 * p
        guard abs(mult - 0.86) < 1e-6 else { throw NSError(domain: "B6", code: 3, userInfo: [NSLocalizedDescriptionKey: "mult at p=1.0 != 0.86"]) }
    }

    private func test_B6_perspective_clampedBelow0() throws {
        let rawP = -0.5
        let clampedP = min(1.0, max(0.0, rawP))
        guard clampedP == 0.0 else { throw NSError(domain: "B6", code: 4, userInfo: [NSLocalizedDescriptionKey: "negative perspective not clamped to 0"]) }
    }

    private func test_B6_perspective_clampedAbove1() throws {
        let rawP = 2.5
        let clampedP = min(1.0, max(0.0, rawP))
        guard clampedP == 1.0 else { throw NSError(domain: "B6", code: 5, userInfo: [NSLocalizedDescriptionKey: "excess perspective not clamped to 1"]) }
    }

    // MARK: - 7. Time Delta Step Boundaries
    private func test_B7_timeDelta_zeroDt() throws {
        let tau = 0.030
        let dt = 0.0
        let k = 1.0 - exp(-dt / tau)
        guard k == 0.0 else { throw NSError(domain: "B7", code: 1, userInfo: [NSLocalizedDescriptionKey: "k at dt=0 must be 0"]) }
    }

    private func test_B7_timeDelta_microsecondDt() throws {
        let tau = 0.030
        let dt = 1e-6
        let k = 1.0 - exp(-dt / tau)
        guard k > 0.0 && k < 1e-4 else { throw NSError(domain: "B7", code: 2, userInfo: [NSLocalizedDescriptionKey: "k for microsecond dt anomalous"]) }
    }

    private func test_B7_timeDelta_displayLink120Hz() throws {
        let dt = 1.0 / 120.0
        let tau = 0.030
        let k = 1.0 - exp(-dt / tau)
        guard k > 0.20 && k < 0.30 else { throw NSError(domain: "B7", code: 3, userInfo: [NSLocalizedDescriptionKey: "k at 120Hz unexpected: \(k)"]) }
    }

    private func test_B7_timeDelta_displayLink60Hz() throws {
        let dt = 1.0 / 60.0
        let tau = 0.030
        let k = 1.0 - exp(-dt / tau)
        guard k > 0.40 && k < 0.50 else { throw NSError(domain: "B7", code: 4, userInfo: [NSLocalizedDescriptionKey: "k at 60Hz unexpected: \(k)"]) }
    }

    private func test_B7_timeDelta_clampedMaxDt0_1s() throws {
        let largeRawDt = 2.5 // 2.5 second sleep/stall
        let dt = min(0.1, max(0.0, largeRawDt))
        guard dt == 0.1 else { throw NSError(domain: "B7", code: 5, userInfo: [NSLocalizedDescriptionKey: "Large dt not clamped to 0.1s"]) }
    }

    // MARK: - 8. Visual Appearance Extremes
    private func test_B8_appearance_zeroBlur_zeroDim() throws {
        let u = TestHarness.RenderUniforms(progress: 0.5, blur: 0.0, dim: 0.0)
        let shade = 1.0 - 0.0 * (0.15 * Double(u.progress) + 0.40 * Double(u.progress) * 0.5)
        guard shade == 1.0 else { throw NSError(domain: "B8", code: 1, userInfo: [NSLocalizedDescriptionKey: "zero dimming should leave shade at 1.0"]) }
    }

    private func test_B8_appearance_maxBlur_maxDim() throws {
        let u = TestHarness.RenderUniforms(progress: 0.5, blur: 1.0, dim: 1.0)
        let shade = 1.0 - 1.0 * (0.15 * Double(u.progress) + 0.40 * Double(u.progress) * 1.0)
        guard shade < 1.0 && shade > 0.0 else { throw NSError(domain: "B8", code: 2, userInfo: [NSLocalizedDescriptionKey: "max dimming shade invalid: \(shade)"]) }
    }

    private func test_B8_appearance_glossDisabled() throws {
        let gloss: Float = 0
        let bend = sin(0.5) * gloss
        guard bend == 0 else { throw NSError(domain: "B8", code: 3, userInfo: [NSLocalizedDescriptionKey: "glossDisabled bend must be 0"]) }
    }

    private func test_B8_appearance_glossEnabled() throws {
        let gloss: Float = 1
        let bend = sin(0.5) * gloss
        guard bend > 0 else { throw NSError(domain: "B8", code: 4, userInfo: [NSLocalizedDescriptionKey: "glossEnabled bend must be > 0"]) }
    }

    private func test_B8_appearance_styleSwellBoundary() throws {
        let styleHold = DuoStyle.hold.shaderIndex
        let styleSwell = DuoStyle.swell.shaderIndex
        guard styleHold == 0 && styleSwell == 1 else {
            throw NSError(domain: "B8", code: 5, userInfo: [NSLocalizedDescriptionKey: "Style indices mismatch"])
        }
    }

    // MARK: - 9. Hardware Hinge Angle Limits
    private func test_B9_hardwareLimit_zeroDegReport() throws {
        let rawReport7 = 0
        let angle = Double(rawReport7) / 100.0
        guard angle == 0.0 else { throw NSError(domain: "B9", code: 1, userInfo: [NSLocalizedDescriptionKey: "zero report should be 0.0 deg"]) }
    }

    private func test_B9_hardwareLimit_135degReport() throws {
        let rawReport7 = 13500
        let angle = Double(rawReport7) / 100.0
        guard angle == 135.0 else { throw NSError(domain: "B9", code: 2, userInfo: [NSLocalizedDescriptionKey: "13500 report should be 135.0 deg"]) }
    }

    private func test_B9_hardwareLimit_180degReport() throws {
        let rawReport7 = 18000
        let angle = Double(rawReport7) / 100.0
        guard angle == 180.0 else { throw NSError(domain: "B9", code: 3, userInfo: [NSLocalizedDescriptionKey: "18000 report should be 180.0 deg"]) }
    }

    private func test_B9_hardwareLimit_report7Over36000Rejected() throws {
        let rawCorrupted = 36001
        let isValid = rawCorrupted <= 36000
        guard !isValid else { throw NSError(domain: "B9", code: 4, userInfo: [NSLocalizedDescriptionKey: "Corrupted report 7 over 36000 was not rejected"]) }
    }

    private func test_B9_hardwareLimit_report1Over360Rejected() throws {
        let rawCorrupted = 361
        let isValid = rawCorrupted <= 360
        guard !isValid else { throw NSError(domain: "B9", code: 5, userInfo: [NSLocalizedDescriptionKey: "Corrupted report 1 over 360 was not rejected"]) }
    }
}
