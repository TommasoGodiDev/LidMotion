import AppKit
@preconcurrency import ScreenCaptureKit
@preconcurrency import CoreMedia
@preconcurrency import CoreVideo
import ImageIO

/// Cattura un singolo fotogramma nativo del display integrato con ScreenCaptureKit.
final class ScreenCapturer: @unchecked Sendable {
    static let shared = ScreenCapturer()

    var hasScreenRecordingPermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    func requestScreenRecordingPermission() {
        CGRequestScreenCaptureAccess()
    }

    /// Descrizione dell'ultimo errore di cattura (nil se l'ultima è riuscita).
    private(set) var lastError: String?

    private var cachedDisplay: SCDisplay?
    private var cachedWallpaper: (key: String, image: CGImage)?

    /// Sfondo scrivania del display, ridimensionato "aspect fill" alla risoluzione nativa.
    func wallpaperImage(for screen: NSScreen) -> CGImage? {
        guard let url = NSWorkspace.shared.desktopImageURL(for: screen) else { return nil }
        let width = Int(screen.frame.width * screen.backingScaleFactor)
        let height = Int(screen.frame.height * screen.backingScaleFactor)
        let key = "\(url.path)-\(width)x\(height)"
        if let cachedWallpaper, cachedWallpaper.key == key { return cachedWallpaper.image }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                      space: CGColorSpace(name: CGColorSpace.displayP3)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        else { return nil }
        let scale = max(CGFloat(width) / CGFloat(image.width), CGFloat(height) / CGFloat(image.height))
        let drawn = CGSize(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale)
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: (CGFloat(width) - drawn.width) / 2, y: (CGFloat(height) - drawn.height) / 2,
                                       width: drawn.width, height: drawn.height))
        guard let result = context.makeImage() else { return nil }
        cachedWallpaper = (key, result)
        return result
    }

    private init() {
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            self?.cachedDisplay = nil
        }
    }

    /// Il completamento viene chiamato sul main thread.
    func captureFrame(displayID: CGDirectDisplayID, completion: @escaping @MainActor (CVPixelBuffer?) -> Void) {
        let cached = cachedDisplay?.displayID == displayID ? cachedDisplay : nil
        Task { @MainActor in
            var frame: CVPixelBuffer?
            var failure: String?
            do {
                let display: SCDisplay
                if let cached {
                    display = cached
                } else {
                    let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                    guard let found = content.displays.first(where: { $0.displayID == displayID }) else {
                        throw NSError(domain: "LidMotion", code: 1,
                                      userInfo: [NSLocalizedDescriptionKey: "Display integrato non trovato"])
                    }
                    display = found
                    self.cachedDisplay = found
                }

                let filter = SCContentFilter(display: display, excludingWindows: [])
                if #available(macOS 14.2, *) { filter.includeMenuBar = true }
                let scale = CGFloat(filter.pointPixelScale)
                let config = SCStreamConfiguration()
                config.width = Int((filter.contentRect.width * scale).rounded())
                config.height = Int((filter.contentRect.height * scale).rounded())
                config.pixelFormat = kCVPixelFormatType_32BGRA
                config.colorSpaceName = CGColorSpace.displayP3
                config.showsCursor = false // il cursore reale resta sopra l'overlay
                config.captureResolution = .best

                let sample = try await SCScreenshotManager.captureSampleBuffer(contentFilter: filter, configuration: config)
                frame = sample.imageBuffer
                if frame == nil { failure = "Fotogramma vuoto" }
            } catch {
                failure = error.localizedDescription
            }
            self.lastError = failure
            if let failure { NSLog("LidMotion: cattura schermo fallita: \(failure)") }
            completion(frame)
        }
    }
}
