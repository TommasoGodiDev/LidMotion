import AppKit
import Metal
import MetalKit
import MetalPerformanceShaders
import CoreVideo
import QuartzCore

/// Stato visivo dell'effetto, derivato dall'angolo del coperchio.
struct FoldState: Equatable {
    /// Rotazione fisica dal piano di riposo, in radianti.
    var tilt: Double = 0
    /// 0..1 avanzamento della chiusura (oscuramento e dissolvenza finale).
    var progress: Double = 0
    /// 0..1 quantità di sfocatura.
    var defocus: Double = 0
    /// 0..1 velocità di chiusura, per la sfocatura da movimento.
    var velocity: Double = 0

    static let clear = FoldState()

    var isNearlyClear: Bool { tilt < 0.0005 && progress < 0.0005 && defocus < 0.0005 && velocity < 0.01 }

    /// `delta` = gradi di chiusura rispetto all'angolo di riposo `reference`.
    static func closing(delta: Double, reference: Double, closeAngle: Double) -> FoldState {
        guard delta > 0, delta.isFinite, reference.isFinite else { return .clear }
        let span = max(20, reference - closeAngle)
        let progress = min(1, delta / span)
        // Appena percettibile nei primi gradi, piena nella seconda metà della chiusura.
        let defocus = 0.18 * ease(delta / 15) * ease(delta / 6)
            + 0.82 * ease((delta - 15) / max(10, span - 15))
        return FoldState(tilt: min(85, delta) * .pi / 180, progress: progress, defocus: min(1, defocus))
    }

    private static func ease(_ x: Double) -> Double {
        let t = min(1, max(0, x))
        return t * t * (3 - 2 * t)
    }
}

/// Parametri di aspetto scelti dall'utente.
struct FoldAppearance {
    var style: LidStyle
    var blur: Double
    var dimming: Double
    var perspective: Double
    var reflections: Double  // 0…1 intensità riflessi

    static var current: FoldAppearance {
        let prefs = PreferencesManager.shared
        return FoldAppearance(style: prefs.style, blur: prefs.blur, dimming: prefs.dimming,
                              perspective: prefs.perspective, reflections: prefs.reflections)
    }
}

/// Deve restare identica a `Uniforms` in FoldShader.swift (13 campi da 4 byte).
private struct FoldUniforms {
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

final class DuoRenderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private let pyramidKernel: MPSImageGaussianPyramid?
    private var textureCache: CVMetalTextureCache?

    /// Fotogramma del desktop catturato all'inizio della chiusura, con piramide di mip.
    private let snapshotLock = NSLock()
    private var _snapshot: MTLTexture?
    var snapshot: MTLTexture? {
        get {
            snapshotLock.lock()
            defer { snapshotLock.unlock() }
            return _snapshot
        }
        set {
            snapshotLock.lock()
            _snapshot = newValue
            snapshotLock.unlock()
        }
    }

    private let stateLock = NSLock()
    private var _current = FoldState.clear
    private var _target = FoldState.clear
    private var _releasing = false
    private var _clearedNotified = true
    
    var current: FoldState {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _current }
        set { stateLock.lock(); _current = newValue; stateLock.unlock() }
    }
    private var target: FoldState {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _target }
        set { stateLock.lock(); _target = newValue; stateLock.unlock() }
    }
    private var releasing: Bool {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _releasing }
        set { stateLock.lock(); _releasing = newValue; stateLock.unlock() }
    }
    var isReleasing: Bool { releasing }
    private var clearedNotified: Bool {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _clearedNotified }
        set { stateLock.lock(); _clearedNotified = newValue; stateLock.unlock() }
    }
    private var lastFrameTime: CFTimeInterval = 0

    /// Chiamato (main thread) quando il primo fotogramma è pronto dopo `show`.
    var onFirstFrame: (() -> Void)?
    /// Chiamato (main thread) quando l'effetto è tornato a riposo dopo `release`.
    var onCleared: (() -> Void)?

    init?(device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
        guard let device, let queue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.commandQueue = queue

        do {
            let library = try device.makeLibrary(source: FoldShader.source, options: nil)
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "duoVertex")
            descriptor.fragmentFunction = library.makeFunction(name: "duoFragment")
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            NSLog("LidMotion: compilazione shader fallita: \(error)")
            return nil
        }

        pyramidKernel = MPSSupportsMTLDevice(device) ? MPSImageGaussianPyramid(device: device) : nil
        super.init()
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
    }

    // MARK: - Animazione

    /// Segue il coperchio in movimento.
    func track(_ state: FoldState) {
        stateLock.lock()
        _target = state
        _releasing = false
        _clearedNotified = false
        stateLock.unlock()
    }

    /// Inizializza l'effetto per l'apertura da coperchio chiuso:
    /// parte da nero assoluto (progress = 1.0, tilt impostato) e sfuma verso lo stato target.
    func startOpening(targetState: FoldState) {
        current = FoldState(tilt: targetState.tilt, progress: 1.0, defocus: 1.0, velocity: 0)
        target = targetState
        releasing = false
        clearedNotified = false
        lastFrameTime = CACurrentMediaTime()
    }

    /// Torna dolcemente allo schermo normale (coperchio fermo o riaperto).
    func release() {
        stateLock.lock()
        _target = .clear
        _releasing = true
        stateLock.unlock()
    }

    func reset() {
        current = .clear
        target = .clear
        releasing = false
        clearedNotified = true
        lastFrameTime = 0
        tiltVel = 0.0
        progVel = 0.0
    }
    private var tiltVel: Double = 0.0
    private var progVel: Double = 0.0

    private func advance(_ rawDt: Double) {
        stateLock.lock()
        defer { stateLock.unlock() }
        // Sub-stepping a 8ms per stabilità matematica assoluta.
        let physicsStep = 0.008
        var remainingDt = rawDt

        // La "velocità animazione" è guidata da PreferencesManager.animationSpeed (0…1).
        // 0.0 → lentissimo (response 0.38s) → quasi nessun lag visivo, massima fluidità.
        // 0.5 → predefinito   (response 0.22s) → buon compromesso velocità/smoothness.
        // 1.0 → velocissimo  (response 0.10s) → reattivo ma rischia microscatti col sensore a 30Hz.
        let speed = PreferencesManager.shared.animationSpeed
        // Range calibrato per evitare lo stuttering del sensore a 30Hz:
        // 0% -> 0.45s (Estremamente fluido, elastico)
        // 100% -> 0.28s (Reattivo ma senza rivelare i saltelli a 30Hz del sensore)
        let response = 0.45 - speed * 0.17
        let omega = 2.0 * .pi / response
        let tension = omega * omega
        let friction = 2.0 * 0.86 * omega

        while remainingDt > 0 {
            let dt = min(remainingDt, physicsStep)

            let tAccel = (_target.tilt - _current.tilt) * tension - tiltVel * friction
            tiltVel += tAccel * dt
            _current.tilt += tiltVel * dt

            let pAccel = (_target.progress - _current.progress) * tension - progVel * friction
            progVel += pAccel * dt
            _current.progress += progVel * dt

            remainingDt -= dt
        }

        let k = 1 - exp(-rawDt / 0.08)
        _current.defocus += (_target.defocus - _current.defocus) * k
        _current.velocity = min(1.0, max(0.0, abs(tiltVel) / 3.5))
        
        if _releasing && _current.isNearlyClear {
            _current = .clear
            if !_clearedNotified {
                _clearedNotified = true
                DispatchQueue.main.async { [weak self] in self?.onCleared?() }
            }
        }
    }

    // MARK: - Snapshot

    func dropSnapshot() {
        self.snapshot = nil
    }

    /// Carica un fotogramma di ScreenCaptureKit (BGRA) e ne costruisce la piramide di sfocatura.
    @discardableResult
    func setSnapshot(pixelBuffer: CVPixelBuffer) -> Bool {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard let texture = makePyramidTexture(width: width, height: height),
              let commandBuffer = commandQueue.makeCommandBuffer() else { return false }

        var cvTexture: CVMetalTexture?
        if let cache = textureCache,
           CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, cache, pixelBuffer, nil,
                                                     .bgra8Unorm, width, height, 0, &cvTexture) == kCVReturnSuccess,
           let cvTexture, let source = CVMetalTextureGetTexture(cvTexture),
           let blit = commandBuffer.makeBlitCommandEncoder() {
            blit.copy(from: source, sourceSlice: 0, sourceLevel: 0,
                      sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                      sourceSize: MTLSize(width: width, height: height, depth: 1),
                      to: texture, destinationSlice: 0, destinationLevel: 0,
                      destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
            blit.endEncoding()
        } else {
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
            guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return false }
            texture.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0,
                            withBytes: base, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer))
        }

        let result = finishPyramid(texture, commandBuffer: commandBuffer)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        withExtendedLifetime(cvTexture) {}
        self.snapshot = result
        return true
    }

    /// Variante per immagini statiche (usata dal test di rendering).
    @discardableResult
    func setSnapshot(image: CGImage) -> Bool {
        let width = image.width, height = image.height
        let space = CGColorSpace(name: CGColorSpace.displayP3)!
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
              let texture = makePyramidTexture(width: width, height: height),
              let commandBuffer = commandQueue.makeCommandBuffer() else { return false }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return false }
        texture.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: data, bytesPerRow: width * 4)
        let result = finishPyramid(texture, commandBuffer: commandBuffer)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        self.snapshot = result
        return true
    }

    private func makePyramidTexture(width: Int, height: Int) -> MTLTexture? {
        guard width > 0, height > 0 else { return nil }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: true)
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .shared
        return device.makeTexture(descriptor: descriptor)
    }

    private func finishPyramid(_ texture: MTLTexture, commandBuffer: MTLCommandBuffer) -> MTLTexture {
        var inPlace = texture
        if let kernel = pyramidKernel,
           kernel.encode(commandBuffer: commandBuffer, inPlaceTexture: &inPlace, fallbackCopyAllocator: nil) {
            return inPlace
        }
        if let blit = commandBuffer.makeBlitCommandEncoder() {
            blit.generateMipmaps(for: texture)
            blit.endEncoding()
        }
        return texture
    }

    // MARK: - Rendering

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        let dt = lastFrameTime == 0 ? 1.0 / 60.0 : min(0.1, max(0, now - lastFrameTime))
        lastFrameTime = now
        advance(dt)

        guard let snapshot,
              let pass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        encode(pass: pass, texture: snapshot, commandBuffer: commandBuffer, state: current, appearance: .current)
        if let firstFrame = onFirstFrame {
            onFirstFrame = nil
            commandBuffer.addCompletedHandler { _ in DispatchQueue.main.async(execute: firstFrame) }
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func encode(pass: MTLRenderPassDescriptor, texture: MTLTexture, commandBuffer: MTLCommandBuffer,
                        state: FoldState, appearance: FoldAppearance) {
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        let perspective = min(1, max(0, appearance.perspective))
        var uniforms = FoldUniforms(
            tilt: Float(state.tilt),
            progress: Float(state.progress),
            defocus: Float(state.defocus),
            style: appearance.style.shaderIndex,
            blur: Float(appearance.blur),
            dim: Float(appearance.dimming),
            perspective: Float(perspective),
            eyeDistance: Float(4.0 - 2.4 * perspective),
            aspect: Float(texture.width) / Float(max(1, texture.height)),
            width: Float(texture.width),
            height: Float(texture.height),
            velocity: Float(state.velocity),
            gloss: Float(appearance.reflections)  // 0…1 intensità riflessi
        )
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<FoldUniforms>.stride, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<FoldUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
    }

    /// Rendering fuori schermo di uno stato (test visivo senza muovere il coperchio).
    func renderImage(state: FoldState, appearance: FoldAppearance) -> CGImage? {
        guard let snapshot else { return nil }
        let width = snapshot.width, height = snapshot.height
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .shared
        guard let output = device.makeTexture(descriptor: descriptor),
              let commandBuffer = commandQueue.makeCommandBuffer() else { return nil }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = output
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        pass.colorAttachments[0].storeAction = .store
        encode(pass: pass, texture: snapshot, commandBuffer: commandBuffer, state: state, appearance: appearance)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        let space = CGColorSpace(name: CGColorSpace.displayP3)!
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                      space: space, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
              let data = context.data else { return nil }
        output.getBytes(data, bytesPerRow: width * 4, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        return context.makeImage()
    }
}
