import SwiftUI
import Combine

final class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var currentAngle: Double = 0.0
    @Published var referenceAngle: Double? = nil
    @Published var hasScreenRecordingPermission: Bool = false
    @Published var isSensorAvailable: Bool = true
    
    private var timer: Timer?

    init() {
        checkPermissions()
        // Poll per i permessi (poiché MacOS non notifica sempre i cambiamenti in tempo reale)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkPermissions()
        }
    }
    
    func checkPermissions() {
        let hasPerm = ScreenCapturer.shared.hasScreenRecordingPermission
        if self.hasScreenRecordingPermission != hasPerm {
            self.hasScreenRecordingPermission = hasPerm
        }
    }
    
    func requestPermissions() {
        ScreenCapturer.shared.requestScreenRecordingPermission()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
