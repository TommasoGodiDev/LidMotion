import AppKit
import MetalKit

/// Finestra a schermo intero sul display integrato che mostra il desktop "piegato".
final class DuoOverlayWindow: NSWindow {

    let renderer: DuoRenderer
    private let metalView: MTKView
    private(set) var isShowing = false

    init(renderer: DuoRenderer) {
        self.renderer = renderer
        let frame = NSScreen.builtIn?.frame ?? NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1470, height: 956)
        metalView = MTKView(frame: NSRect(origin: .zero, size: frame.size), device: renderer.device)

        super.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)

        metalView.colorPixelFormat = .bgra8Unorm
        metalView.colorspace = CGColorSpace(name: CGColorSpace.displayP3)
        metalView.framebufferOnly = true
        metalView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        metalView.enableSetNeedsDisplay = false
        metalView.isPaused = true
        metalView.preferredFramesPerSecond = 120
        metalView.autoresizingMask = [.width, .height]
        metalView.delegate = renderer
        contentView = metalView

        isOpaque = true
        backgroundColor = .black
        hasShadow = false
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
        animationBehavior = .none
        sharingType = .none
        alphaValue = 0
    }

    func show() {
        guard !isShowing, renderer.snapshot != nil, let screen = NSScreen.builtIn else { return }
        isShowing = true
        setFrame(screen.frame, display: false)
        alphaValue = 0
        // Rendi visibile la finestra solo quando il primo fotogramma è pronto: niente flash nero.
        renderer.onFirstFrame = { [weak self] in
            guard let self, self.isShowing else { return }
            self.alphaValue = 1
        }
        orderFrontRegardless()
        metalView.isPaused = false
        metalView.draw()
        // Rete di sicurezza se il callback del primo fotogramma non arriva.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self, self.isShowing else { return }
            self.alphaValue = 1
        }
    }

    func hide() {
        guard isShowing else { return }
        isShowing = false
        metalView.isPaused = true
        renderer.onFirstFrame = nil
        alphaValue = 0
        orderOut(nil)
        renderer.reset()
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    /// Il display integrato del MacBook (non NSScreen.main, che segue la finestra attiva).
    static var builtIn: NSScreen? {
        screens.first { screen in
            guard let id = screen.displayID else { return false }
            return CGDisplayIsBuiltin(id) != 0
        }
    }
}
