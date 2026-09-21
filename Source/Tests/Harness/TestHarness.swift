import Foundation
import Metal
import MetalKit
import CoreGraphics
import QuartzCore

public final class TestHarness {
    public static let shared = TestHarness()

    public private(set) var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipeline: MTLRenderPipelineState?

    private init() {
        if let dev = MTLCreateSystemDefaultDevice() {
            self.device = dev
            self.commandQueue = dev.makeCommandQueue()
            do {
                let library = try dev.makeLibrary(source: FoldShader.source, options: nil)
                let descriptor = MTLRenderPipelineDescriptor()
                descriptor.vertexFunction = library.makeFunction(name: "duoVertex")
                descriptor.fragmentFunction = library.makeFunction(name: "duoFragment")
                descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
                self.pipeline = try dev.makeRenderPipelineState(descriptor: descriptor)
            } catch {
                NSLog("TestHarness: Shader compile error: \(error)")
            }
        }
    }

    // MARK: - Metal Render Helper

    public struct RenderUniforms {
        public var tilt: Float
        public var progress: Float
        public var defocus: Float
        public var style: UInt32
        public var blur: Float
        public var dim: Float
        public var perspective: Float
        public var eyeDistance: Float
        public var aspect: Float
        public var width: Float
        public var height: Float
        public var velocity: Float
        public var gloss: Float

        public init(tilt: Float = 0, progress: Float = 0, defocus: Float = 0, style: UInt32 = 0,
                    blur: Float = 0.7, dim: Float = 0.5, perspective: Float = 0.55, eyeDistance: Float = 2.68,
                    aspect: Float = 1.5376, width: Float = 512, height: Float = 320,
                    velocity: Float = 0, gloss: Float = 1) {
            self.tilt = tilt
            self.progress = progress
            self.defocus = defocus
            self.style = style
            self.blur = blur
            self.dim = dim
            self.perspective = perspective
            self.eyeDistance = eyeDistance
            self.aspect = aspect
            self.width = width
            self.height = height
            self.velocity = velocity
            self.gloss = gloss
        }
    }

    /// Renders a single frame to an offscreen texture and reads back pixel RGBA values
    public func renderToPixels(uniforms: RenderUniforms,
                               width: Int = 128,
                               height: Int = 80) -> [UInt8]? {
        guard let device, let commandQueue, let pipeline else { return nil }

        // Create dummy source texture
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        desc.usage = [.shaderRead, .shaderWrite, .renderTarget]
        desc.storageMode = .shared
        guard let srcTex = device.makeTexture(descriptor: desc),
              let outTex = device.makeTexture(descriptor: desc),
              let cmdBuffer = commandQueue.makeCommandBuffer() else { return nil }

        // Fill source texture with white image (all 255)
        let whitePixels = [UInt8](repeating: 255, count: width * height * 4)
        srcTex.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: whitePixels, bytesPerRow: width * 4)

        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = outTex
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        pass.colorAttachments[0].storeAction = .store

        guard let encoder = cmdBuffer.makeRenderCommandEncoder(descriptor: pass) else { return nil }
        var u = uniforms
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentTexture(srcTex, index: 0)
        encoder.setFragmentBytes(&u, length: MemoryLayout<RenderUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        cmdBuffer.commit()
        cmdBuffer.waitUntilCompleted()

        var result = [UInt8](repeating: 0, count: width * height * 4)
        outTex.getBytes(&result, bytesPerRow: width * 4, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        return result
    }

    // MARK: - Mathematical Oracle Functions

    public static func smoother(_ x: Double) -> Double {
        let cx = min(1.0, max(0.0, x))
        return cx * cx * cx * (cx * (cx * 6.0 - 15.0) + 10.0)
    }

    public static func smoothstep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
        let t = min(1.0, max(0.0, (x - edge0) / (edge1 - edge0)))
        return t * t * (3.0 - 2.0 * t)
    }

    /// Analytical candidate 2 holdPixel projection calculation
    public static func calculateHoldPixel(uv: TestVector2,
                                         u_tilt: Double,
                                         u_perspective: Double,
                                         u_eyeDistance: Double) -> (mapped: TestVector2, sy: Double, t: Double, tilt: Double) {
        let h = 1.0 - uv.y
        let rawTilt = min(1.48, max(0.0, u_tilt))
        let mult = 0.74 + 0.12 * min(1.0, max(0.0, u_perspective))
        let tilt = rawTilt * mult * (1.0 - 0.08 * smoothstep(0.70, 1.40, rawTilt))
        let D = max(u_eyeDistance, 1.3) + 2.5
        let eyeLevel = 0.62
        let denom = D - h * sin(tilt)
        let t = D / denom
        let sy = max(0.0, eyeLevel + t * (h * cos(tilt) - eyeLevel))
        let mapped = TestVector2(0.5 + (uv.x - 0.5) * t, 1.0 - sy)
        return (mapped, sy, t, tilt)
    }

    /// Calculate vertical stretch derivative: d(sy)/dh
    public static func calculateVerticalStretchDerivative(h: Double, tilt: Double, D: Double, eyeLevel: Double = 0.62) -> Double {
        let t = D / (D - h * sin(tilt))
        let B = cos(tilt) - (eyeLevel / D) * sin(tilt)
        return t * t * B
    }

    /// Analytical fade factor calculation: 1.0 - smoothstep(0.65, 0.85, progress)
    public static func calculateFade(progress: Double) -> Double {
        return 1.0 - smoothstep(0.65, 0.85, progress)
    }

    /// Analytical velocity lead calculation from FoldController
    public static func calculateVelocityLead(slope: Double) -> Double {
        let speed = abs(slope)
        let leadFactor = min(1.0, max(0.0, (speed - 4.0) / 8.0))
        return leadFactor * (1.0 / 60.0)
    }

    /// Step response simulation for DuoRenderer with given tau and dt sequence
    public static func simulateExponentialSmoothing(start: Double,
                                                     target: Double,
                                                     tau: Double,
                                                     dt: Double,
                                                     steps: Int) -> [Double] {
        var current = start
        var history: [Double] = [current]
        let k = 1.0 - exp(-dt / tau)
        for _ in 1...steps {
            current += (target - current) * k
            history.append(current)
        }
        return history
    }
}
