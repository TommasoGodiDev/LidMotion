import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    
    private var onPreview: () -> Void
    
    convenience init(onPreview: @escaping () -> Void) {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 620),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        win.title = "LidMotion"
        win.titleVisibility = .hidden
        win.titlebarAppearsTransparent = true
        win.isMovableByWindowBackground = true
        win.center()
        win.isReleasedWhenClosed = false
        
        self.init(window: win)
        self.onPreview = onPreview
        win.delegate = self
        
        updateContentView()
    }
    
    override init(window: NSWindow?) {
        self.onPreview = {}
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateContentView() {
        guard let win = window else { return }
        
        if PreferencesManager.shared.hasCompletedOnboarding {
            let settingsView = SettingsView(onPreview: onPreview)
            let hosting = NSHostingView(rootView: settingsView)
            win.contentView = hosting
            
            // Ridimensiona animato
            var frame = win.frame
            frame.size = NSSize(width: 440, height: 620)
            win.setFrame(frame, display: true, animate: true)
            
        } else {
            let onboardingView = OnboardingView(
                onComplete: { [weak self] in
                    self?.updateContentView()
                },
                onPreview: onPreview
            )
            let hosting = NSHostingView(rootView: onboardingView)
            win.contentView = hosting
            
            var frame = win.frame
            frame.size = NSSize(width: 480, height: 560)
            win.setFrame(frame, display: true, animate: true)
        }
    }
    
    // Live update function called by AppDelegate
    func updateLive(angle: Double, reference: Double?) {
        DispatchQueue.main.async {
            AppState.shared.currentAngle = angle
            AppState.shared.referenceAngle = reference
            // Il sensore c'è
            AppState.shared.isSensorAvailable = true
        }
    }
}
