import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Renderizza l'effetto a vari angoli di chiusura in PNG, per verificarlo senza il sensore.
enum RenderTest {
    static func run(arguments: [String]) -> Int32 {
        guard let outputPath = arguments.first else {
            print("uso: LidMotion --render-test <cartella-output> [immagine]")
            return 2
        }
        guard let renderer = DuoRenderer() else {
            print("Metal non disponibile")
            return 1
        }
        let image: CGImage
        if arguments.count > 1 {
            guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: arguments[1]) as CFURL, nil),
                  let loaded = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                print("impossibile leggere \(arguments[1])")
                return 1
            }
            image = loaded
        } else {
            image = testPattern(width: 2940, height: 1912)
        }
        guard renderer.setSnapshot(image: image) else {
            print("impossibile caricare lo snapshot")
            return 1
        }

        let output = URL(fileURLWithPath: outputPath, isDirectory: true)
        try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let reference = 105.0
        var appearance = FoldAppearance.current
        for style in DuoStyle.allCases {
            appearance.style = style
            for delta in [0.0, 15, 35, 55] {
                let state = FoldState.closing(delta: delta, reference: reference, closeAngle: 10)
                guard let frame = renderer.renderImage(state: state, appearance: appearance) else { continue }
                let url = output.appendingPathComponent("\(style.rawValue)-\(Int(delta)).png")
                if let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) {
                    CGImageDestinationAddImage(destination, frame, nil)
                    CGImageDestinationFinalize(destination)
                }
                print(String(format: "%@  tilt=%.1f° progress=%.2f defocus=%.2f", url.lastPathComponent,
                             state.tilt * 180 / .pi, state.progress, state.defocus))
            }
        }
        return 0
    }

    /// Finto desktop: sfondo, barra dei menu, finestra, griglia ed etichette.
    private static func testPattern(width: Int, height: Int) -> CGImage {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let w = CGFloat(width), h = CGFloat(height)
        NSGradient(starting: NSColor(calibratedRed: 0.10, green: 0.35, blue: 0.75, alpha: 1),
                   ending: NSColor(calibratedRed: 0.85, green: 0.35, blue: 0.55, alpha: 1))!
            .draw(in: NSRect(x: 0, y: 0, width: w, height: h), angle: 90)
        NSColor(white: 1, alpha: 0.25).setStroke()
        let grid = NSBezierPath()
        grid.lineWidth = 3
        for x in stride(from: 0, through: w, by: 147) { grid.move(to: NSPoint(x: x, y: 0)); grid.line(to: NSPoint(x: x, y: h)) }
        for y in stride(from: 0, through: h, by: 147) { grid.move(to: NSPoint(x: 0, y: y)); grid.line(to: NSPoint(x: w, y: y)) }
        grid.stroke()
        NSColor(white: 0.95, alpha: 0.92).setFill()
        NSRect(x: 0, y: h - 64, width: w, height: 64).fill()
        NSColor(white: 0.97, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: w * 0.18, y: h * 0.22, width: w * 0.64, height: h * 0.58), xRadius: 30, yRadius: 30).fill()
        let big: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 150), .foregroundColor: NSColor.black]
        ("LidMotion" as NSString).draw(at: NSPoint(x: w * 0.27, y: h * 0.52), withAttributes: big)
        let small: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 60), .foregroundColor: NSColor.darkGray]
        ("Riga in alto · lontano dalla cerniera" as NSString).draw(at: NSPoint(x: w * 0.24, y: h * 0.70), withAttributes: small)
        ("Riga in basso · vicino alla cerniera" as NSString).draw(at: NSPoint(x: w * 0.24, y: h * 0.28), withAttributes: small)
        NSColor(white: 0.2, alpha: 0.6).setFill()
        NSBezierPath(roundedRect: NSRect(x: w * 0.2, y: 12, width: w * 0.6, height: 110), xRadius: 30, yRadius: 30).fill()
        NSGraphicsContext.restoreGraphicsState()
        return rep.cgImage!
    }
}
