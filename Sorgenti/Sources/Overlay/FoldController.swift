import AppKit
import QuartzCore
import IOKit

/// Traduce l'angolo del coperchio nell'effetto.
final class FoldController {

    private let overlay: DuoOverlayWindow
    private var renderer: DuoRenderer { overlay.renderer }

    private(set) var angle: Double?
    private(set) var reference: Double?

    private var lastSampleTime: CFTimeInterval = 0
    private var stillAnchor = 0.0
    private var stillSince: CFTimeInterval = 0
    private var captureInFlight = false
    private var lastCaptureFailure: CFTimeInterval = -.infinity
    private var snapshotTime: Date?
    private var samples: [(time: CFTimeInterval, angle: Double)] = []
    private var watchdog: Timer?
    private var isOpeningFromClosed = false
    private var stabilityTimer: Timer?

    private let stillBand = 0.5
    private let stillDelay = 0.6
    private let captureDelta = 0.6
    private let showDelta = 1.0


    init(overlay: DuoOverlayWindow) {
        self.overlay = overlay
        renderer.onCleared = { [weak self] in
            guard let self, self.renderer.isReleasing else { return }
            self.hideOverlay()
        }
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, self.overlay.isShowing, CACurrentMediaTime() - self.lastSampleTime > 1.5 else { return }
            self.reset()
        }
        RunLoop.main.add(timer, forMode: .common)
        watchdog = timer
    }

    func handle(angle newAngle: Double) {
        let now = CACurrentMediaTime()
        if now - lastSampleTime > 1.0 {
            restart(at: newAngle, now: now)
        }
        lastSampleTime = now
        angle = newAngle
        let (predicted, slope) = predict(newAngle, at: now)

        if abs(newAngle - stillAnchor) > stillBand {
            stillAnchor = newAngle
            stillSince = now
            
            // L'angolo è cambiato, cancelliamo il timer di stabilità se c'è
            stabilityTimer?.invalidate()
            stabilityTimer = nil
        } else {
            // L'angolo è stabile, avviamo un timer
            if stabilityTimer == nil && overlay.isShowing && newAngle > 60.0 {
                stabilityTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    if self.overlay.isShowing {
                        self.reference = self.angle
                        self.renderer.release()
                    }
                }
            }
        }
        
        if isOpeningFromClosed && newAngle >= (reference ?? 105.0) - 2.0 {
            isOpeningFromClosed = false
        }
        let isStill = isOpeningFromClosed ? false : (now - stillSince >= stillDelay)
        let resting = isStill ? stillAnchor : (reference ?? newAngle)
        let ref = max(resting, newAngle)
        reference = ref

        guard PreferencesManager.shared.isEnabled else {
            hideOverlay()
            return
        }

        let delta = isStill ? 0 : max(0, ref - predicted)
        guard delta > 0.05 else {
            isOpeningFromClosed = false
            if overlay.isShowing {
                renderer.release()
            } else if renderer.snapshot != nil {
                dropSnapshot()
            }
            return
        }

        if !overlay.isShowing {
            if renderer.snapshot == nil, !captureInFlight, delta >= captureDelta, now - lastCaptureFailure > 2.0 {
                captureDesktop()
            }
        }

        var state = FoldState.closing(delta: delta, reference: ref, closeAngle: PreferencesManager.shared.closeAngle)
        state.velocity = min(1, max(0, -slope) / 300)

        if isOpeningFromClosed && !overlay.isShowing {
            renderer.startOpening(targetState: state)
        } else {
            renderer.track(state)
        }

        if !overlay.isShowing, renderer.snapshot != nil, delta >= showDelta {
            overlay.show()
        }
    }

    func reset() {
        hideOverlay()
        lastSampleTime = 0
        isOpeningFromClosed = false
    }

    func runPreview() {
        let start = angle ?? 105
        let span = max(20, start - PreferencesManager.shared.closeAngle)
        let bottom = max(0, start - 0.8 * span)
        LidAngleSensor.shared.simulate(from: start, to: bottom)
    }

    private func predict(_ angle: Double, at now: CFTimeInterval) -> (Double, Double) {
        samples.append((now, angle))
        samples.removeAll { now - $0.time > 0.083 }
        guard samples.count >= 2 else { return (angle, 0) }
        
        let oldest = samples.first!
        let dt = now - oldest.time
        guard dt > 1e-6 else { return (angle, 0) }
        
        let slope = (angle - oldest.angle) / dt
        return (angle, slope)
    }

    private func restart(at angle: Double, now: CFTimeInterval) {
        hideOverlay()
        samples.removeAll()
        isOpeningFromClosed = angle < 80.0
        reference = isOpeningFromClosed ? 105.0 : angle
        stillAnchor = angle
        stillSince = isOpeningFromClosed ? now : now - stillDelay
    }

    private func captureDesktop() {
        guard let displayID = NSScreen.builtIn?.displayID else { return }
        captureInFlight = true
        ScreenCapturer.shared.captureFrame(displayID: displayID) { [weak self] frame in
            guard let self else { return }
            self.captureInFlight = false
            guard !self.overlay.isShowing else { return }
            if let frame, self.renderer.setSnapshot(pixelBuffer: frame) {
                self.snapshotTime = Date()
            } else if let screen = NSScreen.builtIn,
                      let wallpaper = ScreenCapturer.shared.wallpaperImage(for: screen),
                      self.renderer.setSnapshot(image: wallpaper) {
                self.snapshotTime = Date()
            } else {
                self.lastCaptureFailure = CACurrentMediaTime()
            }
        }
    }

    private func hideOverlay() {
        overlay.hide()
        snapshotTime = nil
        isOpeningFromClosed = false
        stabilityTimer?.invalidate()
        stabilityTimer = nil
    }

    private func dropSnapshot() {
        renderer.dropSnapshot()
        snapshotTime = nil
    }
}
