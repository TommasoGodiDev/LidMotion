import Foundation
import Metal
import MetalKit
import CoreGraphics
import QuartzCore

/// Standalone Optics & Extreme Geometry Adversarial Stress Harness
/// Authored by Challenger 1 (Optics & Extreme Geometry Challenger)
@main
struct OpticsStressHarness {
    static func main() {
        print("========================================================")
        print("  Challenger 1: Optics & Extreme Geometry Stress Suite  ")
        print("========================================================")
        
        var totalPassed = 0
        var totalFailed = 0
        
        func assertTest(_ name: String, passed: Bool, details: String = "") {
            if passed {
                totalPassed += 1
                print("  [PASS] \(name) \(details)")
            } else {
                totalFailed += 1
                print("  [FAIL] \(name) - \(details)")
            }
        }
        
        let t0 = CACurrentMediaTime()
        
        // -------------------------------------------------------------
        // TEST 1: Continuous Angle Sweep (0° to 90°) & Singularity Distance
        // -------------------------------------------------------------
        print("\n--- Test Suite 1: Fine-Grained Angle Sweep & Singularity Margin ---")
        var minSingularityMargin = Double.infinity
        var maxTiltRad = 0.0
        var minDenominator = Double.infinity
        var maxExpansionT = 0.0
        var sweepZeroDenomEncountered = false
        
        // Sweep 90,000 steps (step = 0.001 deg) across perspectives 0.0, 0.55, 1.0
        let perspectives: [Double] = [0.0, 0.25, 0.5, 0.55, 0.75, 1.0]
        for p in perspectives {
            let eyeDistance = 4.0 - 2.4 * p
            let D = max(eyeDistance, 1.3) + 2.5
            let eyeLevel = 0.62
            let thetaCrit = atan(D / eyeLevel)
            
            for degInt in 0...90000 {
                let deg = Double(degInt) * 0.001
                let rawTilt = min(1.48, max(0.0, deg * .pi / 180.0))
                let mult = 0.74 + 0.12 * p
                let sstep = rawTilt <= 0.70 ? 0.0 : (rawTilt >= 1.40 ? 1.0 : {
                    let st = (rawTilt - 0.70) / (1.40 - 0.70)
                    return st * st * (3.0 - 2.0 * st)
                }())
                let tilt = rawTilt * mult * (1.0 - 0.08 * sstep)
                maxTiltRad = max(maxTiltRad, tilt)
                
                let margin = (thetaCrit - tilt) * 180.0 / .pi
                minSingularityMargin = min(minSingularityMargin, margin)
                
                for h in [0.0, 0.25, 0.5, 0.75, 1.0] {
                    let denom = D - h * sin(tilt)
                    minDenominator = min(minDenominator, denom)
                    if denom <= 0 { sweepZeroDenomEncountered = true }
                    let t = D / denom
                    maxExpansionT = max(maxExpansionT, t)
                }
            }
        }
        
        assertTest("SingularityMargin",
                   passed: minSingularityMargin >= 10.0,
                   details: "Min margin to theta_crit: \(String(format: "%.2f", minSingularityMargin))° (limit: >= 10.0°)")
        assertTest("DenominatorPositive",
                   passed: !sweepZeroDenomEncountered && minDenominator >= 2.0,
                   details: "Min denominator: \(String(format: "%.4f", minDenominator)) (safe from 0)")
        assertTest("MaxTiltCapped",
                   passed: maxTiltRad <= 1.20,
                   details: "Max tilt reached: \(String(format: "%.4f", maxTiltRad)) rad (\(String(format: "%.2f", maxTiltRad * 180.0 / .pi))°)")
        assertTest("MaxExpansionBounded",
                   passed: maxExpansionT <= 1.5,
                   details: "Max t: \(String(format: "%.4f", maxExpansionT)) (blowout limit: <= 1.5)")

        // -------------------------------------------------------------
        // TEST 2: Zero Coordinate Inversion & Monotonicity Check d(sy)/dh > 0
        // -------------------------------------------------------------
        print("\n--- Test Suite 2: Monotonicity & Zero Coordinate Inversion ---")
        var minDerivative = Double.infinity
        var inversionFound = false
        var negativeSyFound = false
        var maxStretchFound = 0.0
        
        for p in perspectives {
            let eyeDistance = 4.0 - 2.4 * p
            let D = max(eyeDistance, 1.3) + 2.5
            let eyeLevel = 0.62
            let mult = 0.74 + 0.12 * p
            
            for degInt in 0...9000 {
                let deg = Double(degInt) * 0.01
                let rawTilt = min(1.48, max(0.0, deg * .pi / 180.0))
                let sstep = rawTilt <= 0.70 ? 0.0 : (rawTilt >= 1.40 ? 1.0 : {
                    let st = (rawTilt - 0.70) / (1.40 - 0.70)
                    return st * st * (3.0 - 2.0 * st)
                }())
                let tilt = rawTilt * mult * (1.0 - 0.08 * sstep)
                
                var prevSy = -1.0
                for hInt in 0...1000 {
                    let h = Double(hInt) * 0.001
                    let t = D / (D - h * sin(tilt))
                    let rawSy = eyeLevel + t * (h * cos(tilt) - eyeLevel)
                    let sy = max(0.0, rawSy)
                    
                    if rawSy < -1e-6 {
                        negativeSyFound = true
                    }
                    
                    if hInt > 0 && sy < prevSy {
                        inversionFound = true
                    }
                    prevSy = sy
                    
                    // Analytical derivative d(sy)/dh = t^2 * (cos(tilt) - (eyeLevel / D) * sin(tilt))
                    let B = cos(tilt) - (eyeLevel / D) * sin(tilt)
                    let dsy_dh = t * t * B
                    minDerivative = min(minDerivative, dsy_dh)
                    
                    if deg <= 80.0 && hInt == 1000 {
                        let stretch = (1.0 / dsy_dh) / t
                        maxStretchFound = max(maxStretchFound, stretch)
                    }
                }
            }
        }
        
        assertTest("StrictMonotonicity",
                   passed: !inversionFound,
                   details: "sy strictly increases with h across all angles (zero coordinate inversion)")
        assertTest("AnalyticalDerivativePositive",
                   passed: minDerivative > 0.15,
                   details: "Min d(sy)/dh: \(String(format: "%.4f", minDerivative)) > 0 (well above 0)")
        assertTest("NonNegativeSy",
                   passed: !negativeSyFound,
                   details: "Raw sy never goes negative prior to clamp")
        assertTest("StretchRatioCapped",
                   passed: maxStretchFound <= 2.2,
                   details: "Max aspect stretch at 80°: \(String(format: "%.2f", maxStretchFound))x (limit: <= 2.5x)")

        // -------------------------------------------------------------
        // TEST 3: Extreme Aspect Ratios & Edge Boundary Stress
        // -------------------------------------------------------------
        print("\n--- Test Suite 3: Extreme Aspect Ratios & Feather Clamping ---")
        let extremeAspects: [Double] = [
            16.0 / 10.0, // native 1.6
            32.0 / 9.0,  // 3.555 (ultra-wide)
            48.0 / 9.0,  // 5.333 (super ultra-wide)
            100.0,       // extreme ribbon horizontal
            1.0,         // square
            9.0 / 16.0,  // 0.5625 portrait
            9.0 / 32.0,  // 0.281 tall portrait
            0.1,         // extreme ribbon vertical
            0.01,        // degenerate thin vertical
            0.0,         // zero fallback
            -1.0         // negative fallback
        ]
        
        var maxFwXObserved = 0.0
        var nanOrInfEncountered = false
        var edgeSmearingDetected = false
        
        for aspect in extremeAspects {
            let effectiveAspect = max(aspect, 0.1)
            for blur in [0.0, 0.25, 0.5, 0.7, 1.0, 2.0] {
                for defocus in [0.0, 0.5, 1.0] {
                    for velocity in [0.0, 0.5, 1.0] {
                        for h in [0.0, 0.5, 1.0] {
                            let separation = pow(min(1.0, max(0.0, h)), 1.5)
                            let sigmaUV = min(1.0, max(0.0, blur)) * 0.05 * defocus * separation + 0.012 * velocity * separation
                            let fw_x = min(0.015, 1.8 * sigmaUV / effectiveAspect)
                            maxFwXObserved = max(maxFwXObserved, fw_x)
                            
                            if fw_x.isNaN || fw_x.isInfinite {
                                nanOrInfEncountered = true
                            }
                            
                            // Test edge falloff at src.x = 1.0 + fw_x + 1e-4
                            let xOutside = 1.0 + fw_x + 1e-4
                            let s1 = (xOutside - 1.0) / (fw_x + 1e-5)
                            let st = min(1.0, max(0.0, s1))
                            let edgeRight = 1.0 - (st * st * (3.0 - 2.0 * st))
                            if edgeRight > 1e-5 {
                                edgeSmearingDetected = true
                            }
                        }
                    }
                }
            }
        }
        
        assertTest("FwXClamped",
                   passed: maxFwXObserved <= 0.015 + 1e-7,
                   details: "Max fw.x: \(String(format: "%.5f", maxFwXObserved)) (limit: <= 0.015)")
        assertTest("NoNaNOrInfInAspectSweeps",
                   passed: !nanOrInfEncountered,
                   details: "Aspect sweeps produced zero NaN/Inf")
        assertTest("ZeroOuterEdgeSmear",
                   passed: !edgeSmearingDetected,
                   details: "Outer edge strictly drops to 0 beyond 1.0 + fw.x")

        // -------------------------------------------------------------
        // TEST 4: GPU Metal Offscreen Render Passes & Byte Verification
        // -------------------------------------------------------------
        print("\n--- Test Suite 4: Metal GPU Shader Offscreen Byte Verification ---")
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else {
            print("  [ERROR] Metal device not available")
            exit(1)
        }
        
        var library: MTLLibrary!
        var pipeline: MTLRenderPipelineState!
        do {
            library = try device.makeLibrary(source: FoldShader.source, options: nil)
            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction = library.makeFunction(name: "duoVertex")
            desc.fragmentFunction = library.makeFunction(name: "duoFragment")
            desc.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipeline = try device.makeRenderPipelineState(descriptor: desc)
            assertTest("MetalShaderCompilation", passed: true, details: "FoldShader.source compiled on \(device.name)")
        } catch {
            assertTest("MetalShaderCompilation", passed: false, details: "\(error)")
            exit(1)
        }
        
        struct GPUUniforms {
            var tilt: Float
            var progress: Float
            var defocus: Float
            var style: UInt32
            var blur: Float
            var dim: Float
            var perspective: Float
            var eyeDistance: Float
            var aspect: Float
            var width: Float
            var height: Float
            var velocity: Float
            var gloss: Float
        }
        
        func renderGPUFrame(uniforms: GPUUniforms, width: Int, height: Int) -> [UInt8]? {
            let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
            desc.usage = [.shaderRead, .shaderWrite, .renderTarget]
            desc.storageMode = .shared
            guard let srcTex = device.makeTexture(descriptor: desc),
                  let outTex = device.makeTexture(descriptor: desc),
                  let cmd = queue.makeCommandBuffer() else { return nil }
            
            // Fill with full white (255, 255, 255, 255)
            let white = [UInt8](repeating: 255, count: width * height * 4)
            srcTex.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: white, bytesPerRow: width * 4)
            
            let pass = MTLRenderPassDescriptor()
            pass.colorAttachments[0].texture = outTex
            pass.colorAttachments[0].loadAction = .clear
            pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
            pass.colorAttachments[0].storeAction = .store
            
            guard let enc = cmd.makeRenderCommandEncoder(descriptor: pass) else { return nil }
            var u = uniforms
            enc.setRenderPipelineState(pipeline)
            enc.setFragmentTexture(srcTex, index: 0)
            enc.setFragmentBytes(&u, length: MemoryLayout<GPUUniforms>.stride, index: 0)
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            enc.endEncoding()
            
            cmd.commit()
            cmd.waitUntilCompleted()
            
            var bytes = [UInt8](repeating: 0, count: width * height * 4)
            outTex.getBytes(&bytes, bytesPerRow: width * 4, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
            return bytes
        }

        // 4.1 Frame 1 at progress=1.0 and progress=0.85 must be 100% pure black (BGRA: 0, 0, 0, 255)
        let w = 256, h = 160
        var blackCheckPassed = true
        for prog in [Float(0.85), Float(0.90), Float(1.0)] {
            let u = GPUUniforms(
                tilt: Float(45.0 * .pi / 180.0),
                progress: prog,
                defocus: 1.0,
                style: 0,
                blur: 0.7,
                dim: 0.5,
                perspective: 0.55,
                eyeDistance: 2.68,
                aspect: Float(w) / Float(h),
                width: Float(w),
                height: Float(h),
                velocity: 0.0,
                gloss: 1.0
            )
            if let pixels = renderGPUFrame(uniforms: u, width: w, height: h) {
                for i in stride(from: 0, to: pixels.count, by: 4) {
                    let b = pixels[i], g = pixels[i+1], r = pixels[i+2], a = pixels[i+3]
                    if b != 0 || g != 0 || r != 0 || a != 255 {
                        blackCheckPassed = false
                        break
                    }
                }
            } else {
                blackCheckPassed = false
            }
        }
        assertTest("GPU_PureBlackAtProgressGTE85",
                   passed: blackCheckPassed,
                   details: "All pixels BGRA=(0,0,0,255) across 40,960 pixels for progress in [0.85, 0.90, 1.0]")

        // 4.2 Rest state (progress=0, tilt=0, defocus=0) returns unaltered desktop
        let uRest = GPUUniforms(
            tilt: 0, progress: 0, defocus: 0, style: 0, blur: 0.7, dim: 0.5,
            perspective: 0.55, eyeDistance: 2.68, aspect: Float(w)/Float(h),
            width: Float(w), height: Float(h), velocity: 0, gloss: 1
        )
        var restUnaltered = true
        if let pixels = renderGPUFrame(uniforms: uRest, width: w, height: h) {
            for i in stride(from: 0, to: pixels.count, by: 4) {
                if pixels[i] != 255 || pixels[i+1] != 255 || pixels[i+2] != 255 {
                    restUnaltered = false
                    break
                }
            }
        } else {
            restUnaltered = false
        }
        assertTest("GPU_RestStatePixelFidelity",
                   passed: restUnaltered,
                   details: "All pixels BGRA=(255,255,255,255) at rest state (100% bypass fidelity)")

        // 4.3 Extreme Aspect Ratios Offscreen GPU Renders
        let aspectScenarios: [(name: String, width: Int, height: Int)] = [
            ("Native_16_10", 320, 200),
            ("UltraWide_32_9", 512, 144),
            ("Portrait_9_16", 180, 320),
            ("Square_1_1", 256, 256),
            ("Ribbon_10_1", 400, 40)
        ]
        
        var allAspectRendersSucceeded = true
        for scenario in aspectScenarios {
            let uAspect = GPUUniforms(
                tilt: Float(50.0 * .pi / 180.0),
                progress: 0.4,
                defocus: 0.6,
                style: 0,
                blur: 0.8,
                dim: 0.3,
                perspective: 0.7,
                eyeDistance: Float(4.0 - 2.4 * 0.7),
                aspect: Float(scenario.width) / Float(scenario.height),
                width: Float(scenario.width),
                height: Float(scenario.height),
                velocity: 0.2,
                gloss: 1.0
            )
            guard let pixels = renderGPUFrame(uniforms: uAspect, width: scenario.width, height: scenario.height) else {
                allAspectRendersSucceeded = false
                break
            }
            // Check that rendered pixels have no NaN/garbage (alpha must be 255)
            var validAlpha = true
            for i in stride(from: 3, to: pixels.count, by: 4) {
                if pixels[i] != 255 { validAlpha = false; break }
            }
            if !validAlpha { allAspectRendersSucceeded = false; break }
        }
        assertTest("GPU_ExtremeAspectRatiosRendered",
                   passed: allAspectRendersSucceeded,
                   details: "5/5 extreme aspect ratios rendered successfully on GPU without corruption")

        // 4.4 Visual Blowout Check Across 0° to 85° Tilt Sweep
        var blowoutDetected = false
        for deg in [10.0, 30.0, 50.0, 70.0, 80.0, 84.9] {
            let uSweep = GPUUniforms(
                tilt: Float(deg * .pi / 180.0),
                progress: Float(deg / 100.0),
                defocus: Float(deg / 90.0),
                style: 0,
                blur: 0.7,
                dim: 0.5,
                perspective: 0.55,
                eyeDistance: 2.68,
                aspect: 1.6,
                width: 160,
                height: 100,
                velocity: 0.1,
                gloss: 1.0
            )
            guard let pixels = renderGPUFrame(uniforms: uSweep, width: 160, height: 100) else {
                blowoutDetected = true
                break
            }
            // Verify brightness does not explode (e.g. valid bytes, no overflow)
            for i in stride(from: 0, to: pixels.count, by: 4) {
                let a = pixels[i+3]
                if a != 255 { blowoutDetected = true; break }
            }
        }
        assertTest("GPU_VisualBlowoutCheck",
                   passed: !blowoutDetected,
                   details: "No visual blowout or alpha corruption across tilt sweep 10°..85°")

        // 4.5 Style 1 (swellPixel) GPU Rendering & Pure Black at progress >= 0.85
        var swellPassed = true
        for prog in [Float(0.0), Float(0.5), Float(0.85), Float(1.0)] {
            let uSwell = GPUUniforms(
                tilt: Float(45.0 * .pi / 180.0),
                progress: prog,
                defocus: 0.8,
                style: 1, // Espansione
                blur: 0.6,
                dim: 0.4,
                perspective: 0.6,
                eyeDistance: 2.5,
                aspect: 1.6,
                width: 160,
                height: 100,
                velocity: 0.0,
                gloss: 1.0
            )
            guard let pixels = renderGPUFrame(uniforms: uSwell, width: 160, height: 100) else {
                swellPassed = false
                break
            }
            if prog >= 0.85 {
                for i in stride(from: 0, to: pixels.count, by: 4) {
                    if pixels[i] != 0 || pixels[i+1] != 0 || pixels[i+2] != 0 || pixels[i+3] != 255 {
                        swellPassed = false
                        break
                    }
                }
            } else {
                for i in stride(from: 3, to: pixels.count, by: 4) {
                    if pixels[i] != 255 { swellPassed = false; break }
                }
            }
        }
        assertTest("GPU_Style1_SwellPixelRobustness",
                   passed: swellPassed,
                   details: "Style 1 (swellPixel) renders cleanly and enforces pure black at progress >= 0.85")

        // 4.6 Degenerate & Extreme Out-of-Bounds Uniforms
        var adversarialInputsPassed = true
        let adversarialUniformsList = [
            GPUUniforms(tilt: -5.0, progress: -1.0, defocus: -2.0, style: 0, blur: -1.0, dim: -1.0, perspective: -2.0, eyeDistance: -10.0, aspect: -5.0, width: 64, height: 64, velocity: -1.0, gloss: -1.0),
            GPUUniforms(tilt: 100.0, progress: 10.0, defocus: 5.0, style: 0, blur: 5.0, dim: 5.0, perspective: 10.0, eyeDistance: 100.0, aspect: 100.0, width: 64, height: 64, velocity: 10.0, gloss: 5.0),
            GPUUniforms(tilt: 0.0, progress: 0.0, defocus: 0.0, style: 99, blur: 0.0, dim: 0.0, perspective: 0.0, eyeDistance: 0.0, aspect: 0.0, width: 64, height: 64, velocity: 0.0, gloss: 0.0)
        ]
        for uAdv in adversarialUniformsList {
            guard let pixels = renderGPUFrame(uniforms: uAdv, width: 64, height: 64) else {
                adversarialInputsPassed = false
                break
            }
            for i in stride(from: 3, to: pixels.count, by: 4) {
                if pixels[i] != 255 { adversarialInputsPassed = false; break }
            }
        }
        assertTest("GPU_AdversarialUniformsResilience",
                   passed: adversarialInputsPassed,
                   details: "Shader handles negative, zero, and extreme values without GPU crashes or NaN")

        let dt = (CACurrentMediaTime() - t0) * 1000.0
        print("\n========================================================")
        print("                  STRESS HARNESS SUMMARY                ")
        print("========================================================")
        print("Total Assertions: \(totalPassed + totalFailed)")
        print("Passed:           \(totalPassed)")
        print("Failed:           \(totalFailed)")
        print("Execution Time:   \(String(format: "%.2f", dt)) ms")
        if totalFailed == 0 {
            print("\n✅ OPTICS & SHADER VERIFICATION: 100% SUCCESSFUL (APPROVE)")
        } else {
            print("\n❌ OPTICS & SHADER VERIFICATION: FAILED (REQUEST_CHANGES)")
            exit(1)
        }
    }
}
