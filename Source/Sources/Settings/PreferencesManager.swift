import Foundation
import Combine

enum LidStyle: String, CaseIterable, Identifiable {
    case hold
    case swell
    case fade
    case crt
    case sleep
    case glitch
    case notch

    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .hold: return "Duo"
        case .swell: return "Expansion"
        case .fade: return "Fade"
        case .crt: return "CRT Monitor"
        case .sleep: return "Sleep"
        case .glitch: return "Glitch"
        case .notch: return "Notch Drop"
        }
    }

    var shaderIndex: UInt32 {
        switch self {
        case .hold: return 0
        case .swell: return 1
        case .fade: return 2
        case .crt: return 3
        case .sleep: return 4
        case .glitch: return 5
        case .notch: return 6
        }
    }
}


/* LidSound enum removed */
enum OldLidSound: String {
    case none = "none"
    case crtPowerOff = "crt"
    case mechClick = "mech"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .none: return "None"
        case .crtPowerOff: return "CRT Power Off"
        case .mechClick: return "Mechanical Click"
        }
    }
}

enum LidColor: String, CaseIterable, Identifiable {
    case none = "none"
    case green = "green"
    case amber = "amber"
    case blue = "blue"
    case red = "red"
    case purple = "purple"
    var id: String { rawValue }
    var title: String {
        switch self {
        case .none: return "None (Original)"
        case .green: return "Matrix Green"
        case .amber: return "Vintage Amber"
        case .blue: return "Deep Blue"
        case .red: return "Vampire Red"
        case .purple: return "Neon Purple"
        }
    }
}

enum LidPreset: String, CaseIterable, Identifiable {
    case standard = "Default"
    case subtle = "Subtle"
    case strong = "Strong"
    case custom = "Custom"
    
    var id: String { rawValue }
}

final class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager()
    private let defaults = UserDefaults.standard

    enum Keys {
        static let isEnabled      = "LidMotion_isEnabled"
        static let hasCompletedOnboarding = "LidMotion_onboarding"
        
        static let style          = "LidMotion_style"
        static let blur           = "LidMotion_blur"
        static let dimming        = "LidMotion_dimming"
        static let perspective    = "LidMotion_perspective"
        static let closeAngle     = "LidMotion_closeAngle"
        static let reflections    = "LidMotion_reflections"
        static let animationSpeed = "LidMotion_animationSpeed"
        static let preset         = "LidMotion_preset"
        static let soundEnabled = "LidMotion_soundEnabled"
        static let tintColor      = "LidMotion_tintColor"
    }

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }
    /* @Published var sound: LidSound {
        */
    
    @Published var tintColor: LidColor {
        didSet { defaults.set(tintColor.rawValue, forKey: Keys.tintColor) }
    }

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }
    
    private func styleKey(_ baseKey: String) -> String {
        return "\(baseKey)_\(style.rawValue)"
    }

    @Published var style: LidStyle {
        didSet { 
            defaults.set(style.rawValue, forKey: Keys.style)
            loadSettingsForCurrentStyle()
        }
    }
    
    @Published var preset: LidPreset {
        didSet { 
            if !isLoading { defaults.set(preset.rawValue, forKey: styleKey(Keys.preset)) }
            if preset != .custom { applyPreset(preset) }
        }
    }

    @Published var blur: Double {
        didSet { if !isLoading { defaults.set(blur, forKey: styleKey(Keys.blur)); checkCustom() } }
    }

    @Published var dimming: Double {
        didSet { if !isLoading { defaults.set(dimming, forKey: styleKey(Keys.dimming)); checkCustom() } }
    }

    @Published var perspective: Double {
        didSet { if !isLoading { defaults.set(perspective, forKey: styleKey(Keys.perspective)); checkCustom() } }
    }

    @Published var closeAngle: Double {
        didSet { if !isLoading { defaults.set(closeAngle, forKey: styleKey(Keys.closeAngle)); checkCustom() } }
    }

    @Published var reflections: Double {
        didSet { if !isLoading { defaults.set(reflections, forKey: styleKey(Keys.reflections)); checkCustom() } }
    }

    @Published var animationSpeed: Double {
        didSet { if !isLoading { defaults.set(animationSpeed, forKey: styleKey(Keys.animationSpeed)); checkCustom() } }
    }

    private var isApplyingPreset = false
    private var isLoading = false

    init() {
        self.isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        self.soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? false
        self.tintColor = LidColor(rawValue: defaults.string(forKey: Keys.tintColor) ?? "") ?? LidColor.none
        self.hasCompletedOnboarding = defaults.object(forKey: Keys.hasCompletedOnboarding) as? Bool ?? false
        
        self.style = LidStyle(rawValue: defaults.string(forKey: Keys.style) ?? "") ?? .hold
        
        // Inizializza temporaneamente con valori fake prima di chiamare loadSettingsForCurrentStyle
        self.preset = .standard
        self.blur = 0.6
        self.dimming = 0.4
        self.perspective = 0.50
        self.closeAngle = 10.0
        self.reflections = 0.75
        self.animationSpeed = 0.5
        
        loadSettingsForCurrentStyle()
    }
    
    private func loadSettingsForCurrentStyle() {
        isLoading = true
        
        self.preset = LidPreset(rawValue: defaults.string(forKey: styleKey(Keys.preset)) ?? "") ?? .standard
        
        // Se non ci sono salvataggi per questo stile, applichiamo il preset standard di quello stile
        if defaults.object(forKey: styleKey(Keys.blur)) == nil {
            applyPreset(.standard)
        } else {
            self.blur = min(1, max(0, defaults.object(forKey: styleKey(Keys.blur)) as? Double ?? 0.60))
            self.dimming = min(1, max(0, defaults.object(forKey: styleKey(Keys.dimming)) as? Double ?? 0.40))
            self.perspective = min(1, max(0, defaults.object(forKey: styleKey(Keys.perspective)) as? Double ?? 0.50))
            self.closeAngle = min(45, max(0, defaults.object(forKey: styleKey(Keys.closeAngle)) as? Double ?? 10.0))
            self.reflections = min(1, max(0, defaults.object(forKey: styleKey(Keys.reflections)) as? Double ?? 0.75))
            self.animationSpeed = min(1, max(0, defaults.object(forKey: styleKey(Keys.animationSpeed)) as? Double ?? 0.50))
        }
        
        isLoading = false
    }

    private func applyPreset(_ p: LidPreset) {
        guard !isApplyingPreset else { return }
        isApplyingPreset = true
        let oldIsLoading = isLoading
        isLoading = true
        
        switch style {
        case .hold:
            if p == .standard { setParams(b: 0.60, d: 0.40, p: 0.50, r: 0.75, s: 0.50, a: 10.0) }
            else if p == .subtle { setParams(b: 0.30, d: 0.20, p: 0.50, r: 0.40, s: 0.20, a: 15.0) }
            else if p == .strong { setParams(b: 0.90, d: 0.70, p: 1.00, r: 1.00, s: 0.80, a: 5.0) }
        case .swell:
            if p == .standard { setParams(b: 0.50, d: 0.50, p: 0.80, r: 0.50, s: 0.50, a: 10.0) }
            else if p == .subtle { setParams(b: 0.20, d: 0.30, p: 0.40, r: 0.20, s: 0.30, a: 15.0) }
            else if p == .strong { setParams(b: 0.80, d: 0.80, p: 1.00, r: 0.80, s: 0.80, a: 5.0) }
        case .fade:
            if p == .standard { setParams(b: 0.80, d: 0.60, p: 0.00, r: 0.00, s: 0.60, a: 5.0) }
            else if p == .subtle { setParams(b: 0.40, d: 0.30, p: 0.00, r: 0.00, s: 0.30, a: 10.0) }
            else if p == .strong { setParams(b: 1.00, d: 1.00, p: 0.00, r: 0.00, s: 0.90, a: 2.0) }
        case .crt:
            if p == .standard { setParams(b: 0.20, d: 0.70, p: 0.00, r: 0.00, s: 0.80, a: 15.0) }
            else if p == .subtle { setParams(b: 0.00, d: 0.40, p: 0.00, r: 0.00, s: 0.50, a: 20.0) }
            else if p == .strong { setParams(b: 0.50, d: 1.00, p: 0.00, r: 0.00, s: 1.00, a: 8.0) }
        case .sleep:
            if p == .standard { setParams(b: 1.00, d: 0.90, p: 0.00, r: 0.00, s: 0.40, a: 5.0) }
            else if p == .subtle { setParams(b: 0.60, d: 0.60, p: 0.00, r: 0.00, s: 0.20, a: 10.0) }
            else if p == .strong { setParams(b: 1.00, d: 1.00, p: 0.00, r: 0.00, s: 0.70, a: 3.0) }
        case .glitch:
            if p == .standard { setParams(b: 0.40, d: 0.50, p: 0.00, r: 0.20, s: 0.90, a: 10.0) }
            else if p == .subtle { setParams(b: 0.10, d: 0.20, p: 0.00, r: 0.00, s: 0.50, a: 15.0) }
            else if p == .strong { setParams(b: 0.80, d: 0.90, p: 0.00, r: 0.50, s: 1.00, a: 5.0) }
        case .notch:
            if p == .standard { setParams(b: 0.80, d: 1.00, p: 0.00, r: 0.00, s: 0.50, a: 10.0) }
            else if p == .subtle { setParams(b: 0.50, d: 0.80, p: 0.00, r: 0.00, s: 0.30, a: 15.0) }
            else if p == .strong { setParams(b: 1.00, d: 1.00, p: 0.00, r: 0.00, s: 0.80, a: 5.0) }
        }
        
        isLoading = oldIsLoading
        isApplyingPreset = false
        
        // Forza il salvataggio manuale dei preset attivi dato che isLoading era true
        if !isLoading {
            defaults.set(blur, forKey: styleKey(Keys.blur))
            defaults.set(dimming, forKey: styleKey(Keys.dimming))
            defaults.set(perspective, forKey: styleKey(Keys.perspective))
            defaults.set(closeAngle, forKey: styleKey(Keys.closeAngle))
            defaults.set(reflections, forKey: styleKey(Keys.reflections))
            defaults.set(animationSpeed, forKey: styleKey(Keys.animationSpeed))
        }
    }
    
    private func setParams(b: Double, d: Double, p: Double, r: Double, s: Double, a: Double) {
        blur = b
        dimming = d
        perspective = p
        reflections = r
        animationSpeed = s
        closeAngle = a
    }

    private func checkCustom() {
        if !isApplyingPreset && preset != .custom {
            preset = .custom
        }
    }

    func resetToDefaults() {
        preset = .standard
    }
}
