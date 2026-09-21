import SwiftUI
import AppKit

struct IconView: View {
    var body: some View {
        ZStack {
            // Sfondo scuro e profondo
            Color(red: 0.05, green: 0.05, blue: 0.08)
            
            // "Liquid Glass" Holographic Blobs (colori fluidi sfocati sullo sfondo)
            Circle()
                .fill(Color.cyan)
                .frame(width: 600, height: 600)
                .blur(radius: 130)
                .offset(x: -250, y: -250)
                .opacity(0.6)
                
            Circle()
                .fill(Color.purple)
                .frame(width: 700, height: 700)
                .blur(radius: 150)
                .offset(x: 250, y: 200)
                .opacity(0.5)
                
            Circle()
                .fill(Color.blue)
                .frame(width: 600, height: 600)
                .blur(radius: 120)
                .offset(x: -150, y: 300)
                .opacity(0.4)
                
            // Glassmorphism Floating Card
            RoundedRectangle(cornerRadius: 160, style: .continuous)
                .fill(
                    LinearGradient(colors: [.white.opacity(0.18), .white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 660, height: 660)
                .overlay(
                    RoundedRectangle(cornerRadius: 160, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [.white.opacity(0.6), .clear, .white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 5
                        )
                )
                .shadow(color: .black.opacity(0.4), radius: 40, x: 0, y: 20)

            // Simbolo MacBook ultra-minimale
            Image(systemName: "macbook")
                .resizable()
                .scaledToFit()
                .frame(width: 550)
                .foregroundStyle(
                    LinearGradient(colors: [.white, Color(white: 0.7)], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .black.opacity(0.5), radius: 25, x: 0, y: 15)
                
            // Leggero bagliore neon dietro il macbook
            Image(systemName: "macbook")
                .resizable()
                .scaledToFit()
                .frame(width: 550)
                .foregroundStyle(.cyan)
                .blur(radius: 40)
                .opacity(0.4)
                .blendMode(.screen)
        }
        .frame(width: 1024, height: 1024)
        // Arrotondamento standard per le icone macOS (22.5% del lato)
        .clipShape(RoundedRectangle(cornerRadius: 230, style: .continuous))
    }
}

let app = NSApplication.shared

DispatchQueue.main.async {
    let view = IconView()
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0

    if let image = renderer.nsImage {
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            let url = URL(fileURLWithPath: "AppIcon_1024.png")
            try? pngData.write(to: url)
            print("SUCCESS")
        } else {
            print("FAILED TO RENDER DATA")
        }
    } else {
        print("FAILED TO RENDER IMAGE")
    }
    NSApp.terminate(nil)
}

app.run()
