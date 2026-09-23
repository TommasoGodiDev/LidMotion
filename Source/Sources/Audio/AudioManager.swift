import Foundation
import AppKit

enum LidSoundType {
    case crtPowerOff
    case mechClick
    case duoPad
    case glitchNoise
    case shoosh
}

final class AudioManager {
    static let shared = AudioManager()
    
    private var crtSound: NSSound?
    private var mechSound: NSSound?
    private var duoSound: NSSound?
    private var glitchSound: NSSound?
    private var shooshSound: NSSound?
    
    private var currentContinuous: NSSound?
    
    private init() {
        if let url = Bundle.main.url(forResource: "crt_power", withExtension: "wav") {
            crtSound = NSSound(contentsOf: url, byReference: true)
            crtSound?.volume = 0.35
        }
        if let url = Bundle.main.url(forResource: "mech_click", withExtension: "wav") {
            mechSound = NSSound(contentsOf: url, byReference: true)
            mechSound?.volume = 0.25
        }
        if let url = Bundle.main.url(forResource: "glitch_noise", withExtension: "wav") {
            glitchSound = NSSound(contentsOf: url, byReference: true)
            glitchSound?.loops = true
            glitchSound?.volume = 0.15
        }
        if let url = Bundle.main.url(forResource: "shoosh", withExtension: "wav") {
            shooshSound = NSSound(contentsOf: url, byReference: true)
            shooshSound?.loops = true
            shooshSound?.volume = 0.2
        }
    }
    
    func playSound(_ soundType: LidSoundType) {
        switch soundType {
        case .crtPowerOff:
            crtSound?.stop()
            crtSound?.play()
        case .mechClick:
            mechSound?.stop()
            mechSound?.play()
        default: break
        }
    }
    
    func startContinuous(_ soundType: LidSoundType) {
        var target: NSSound?
        switch soundType {
        case .duoPad: target = duoSound
        case .glitchNoise: target = glitchSound
        case .shoosh: target = shooshSound
        default: return
        }
        
        if currentContinuous != target {
            currentContinuous?.stop()
            currentContinuous = target
            currentContinuous?.play()
        } else if !(currentContinuous?.isPlaying ?? false) {
            currentContinuous?.play()
        }
    }
    
    func stopContinuous() {
        currentContinuous?.stop()
        currentContinuous = nil
    }
}
