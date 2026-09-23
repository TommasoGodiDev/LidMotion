import SwiftUI

struct SettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared
    @ObservedObject var appState = AppState.shared
    
    var onPreview: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    appearanceSection
                    behaviorSection
                    Text("LidMotion v1.2").font(.system(size: 10)).foregroundColor(.secondary).padding(.top, 10).frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(24)
                .frame(maxWidth: 420)
            }
            
            Divider()
            
            footerSection
        }
        .frame(width: 440, height: 620)
        // macOS Sequoia "Liquid Glass" base background
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "macbook")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 40)
                .foregroundColor(.accentColor)
                .fontWeight(.thin)
                .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            
            Text("LidMotion")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
            
            Text("Holographic display folding effect")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
    
    // MARK: - Appearance
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("APPEARANCE")
            
            LiquidBox {
                VStack(spacing: 12) {
                    HStack {
                        Label("Style", systemImage: "square.on.square")
                        Spacer()
                        Picker("", selection: $prefs.style) {
                            ForEach(LidStyle.allCases) { style in
                                Text(style.title).tag(style)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 170)
                    }
                    
                    Divider().opacity(0.5)
                    
                    HStack {
                        Label("Preset", systemImage: "wand.and.stars")
                        Spacer()
                        Picker("", selection: $prefs.preset) {
                            ForEach(LidPreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 170)
                    }
                    
                    Divider().opacity(0.5)
                    
                    // Custom sliders tailored for each effect mapping to the existing 4 variables
                    switch prefs.style {
                    case .hold, .swell:
                        SliderRow(icon: "drop.halffull", title: "Blur", value: $prefs.blur, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "circle.lefthalf.filled", title: "Dimming", value: $prefs.dimming, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "view.3d", title: "Perspective", value: $prefs.perspective, range: 0...1, format: "%.0f%%", multiplier: 100)
                        if prefs.style == .hold {
                            Text("Adjust the perspective to your liking to get the desired Duo effect.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                        }
                        Divider().opacity(0.5)
                        SliderRow(icon: "sparkles", title: "Reflections", value: $prefs.reflections, range: 0...1, format: "%.0f%%", multiplier: 100)
                    case .fade:
                        SliderRow(icon: "drop.halffull", title: "Blur", value: $prefs.blur, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "circle.lefthalf.filled", title: "Dimming", value: $prefs.dimming, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "paintbrush", title: "Desaturate", value: $prefs.perspective, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "arrow.down.right.and.arrow.up.left", title: "Scale Down", value: $prefs.reflections, range: 0...1, format: "%.0f%%", multiplier: 100)
                    case .sleep:
                        SliderRow(icon: "drop.halffull", title: "Blur", value: $prefs.blur, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "circle.lefthalf.filled", title: "Dimming", value: $prefs.dimming, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "plus.magnifyingglass", title: "Zoom", value: $prefs.perspective, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "paintbrush", title: "Desaturate", value: $prefs.reflections, range: 0...1, format: "%.0f%%", multiplier: 100)
                    case .crt:
                        SliderRow(icon: "circle.lefthalf.filled", title: "Dimming", value: $prefs.dimming, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "eye.slash", title: "Aberration", value: $prefs.blur, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "tv", title: "Curvature", value: $prefs.perspective, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "lines.measurement.horizontal", title: "Scanlines", value: $prefs.reflections, range: 0...1, format: "%.0f%%", multiplier: 100)
                    case .glitch:
                        SliderRow(icon: "circle.lefthalf.filled", title: "Dimming", value: $prefs.dimming, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "squareshape.split.2x2", title: "Block Noise", value: $prefs.blur, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "square.split.diagonal.2x2", title: "RGB Split", value: $prefs.perspective, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "bolt.horizontal", title: "Scanlines", value: $prefs.reflections, range: 0...1, format: "%.0f%%", multiplier: 100)
                    case .notch:
                        SliderRow(icon: "drop.halffull", title: "Blur", value: $prefs.blur, range: 0...1, format: "%.0f%%", multiplier: 100)
                        Divider().opacity(0.5)
                        SliderRow(icon: "circle.lefthalf.filled", title: "Dimming", value: $prefs.dimming, range: 0...1, format: "%.0f%%", multiplier: 100)
                    }
                    if prefs.style == .crt || prefs.style == .glitch || prefs.style == .fade {
                        Divider().opacity(0.5)
                        HStack {
                            Image(systemName: "paintpalette.fill").frame(width: 20).foregroundColor(.secondary)
                            Text("Color Tint").frame(width: 90, alignment: .leading)
                            Picker("", selection: $prefs.tintColor) {
                                ForEach(LidColor.allCases) { c in Text(c.title).tag(c) }
                            }
                            .labelsHidden()
                            .pickerStyle(MenuPickerStyle())
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Behavior
    
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("BEHAVIOR")
            
            LiquidBox {
                VStack(spacing: 12) {
                    SliderRow(icon: "bolt.fill", title: "Response", value: $prefs.animationSpeed, range: 0...1, format: "%.0f%%", multiplier: 100)
                    Divider().opacity(0.5)
                    SliderRow(icon: "moon.fill", title: "Close at", value: $prefs.closeAngle, range: 0...45, format: "%.0f°", multiplier: 1)
                    Divider().opacity(0.5)
                    HStack {
                        Image(systemName: "speaker.wave.2.fill").frame(width: 20).foregroundColor(.secondary)
                        Toggle("Sound Effects", isOn: $prefs.soundEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        HStack {
            Button("Reset to Defaults") {
                withAnimation {
                    prefs.resetToDefaults()
                }
            }
            
            
            Spacer()
            
            Button("Preview Animation") {
                onPreview()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.3))
    }
    
    // MARK: - Helpers
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.leading, 4)
    }
}

// MARK: - Liquid Glass Box

struct LiquidBox<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Reusable Components

struct SliderRow: View {
    var icon: String
    var title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var format: String
    var multiplier: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)
            
            Text(title)
                .frame(width: 90, alignment: .leading)
            
            Slider(value: $value, in: range)
            
            Text(String(format: format, value * multiplier))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 45, alignment: .trailing)
        }
    }
}

// MARK: - Visual Effect View

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
