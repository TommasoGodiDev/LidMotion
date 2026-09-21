import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var overlayWindow: DuoOverlayWindow!
    private var controller: FoldController!
    private var settingsController: SettingsWindowController?

    private var angleMenuItem: NSMenuItem!
    private var enabledMenuItem: NSMenuItem!
    private var permissionMenuItem: NSMenuItem!
    private var launchAtLoginMenuItem: NSMenuItem!

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Nascondi icona nel Dock (app barra dei menu)
        NSApp.setActivationPolicy(.accessory)

        guard let renderer = DuoRenderer() else {
            let alert = NSAlert()
            alert.messageText = "LidMotion cannot start"
            alert.informativeText = "Metal is not available on this Mac."
            alert.runModal()
            NSApp.terminate(nil)
            return
        }
        overlayWindow = DuoOverlayWindow(renderer: renderer)
        controller = FoldController(overlay: overlayWindow)

        setupStatusItem()
        setupSensor()
        observeSystemEvents()

        // APRI AUTOMATICAMENTE LE IMPOSTAZIONI ALL'AVVIO se onboarding non completato
        if !PreferencesManager.shared.hasCompletedOnboarding {
            openSettings()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "macbook", accessibilityDescription: "LidMotion")
            image?.isTemplate = true
            button.image = image
            button.title = ""
            button.toolTip = "LidMotion"
        }

        let menu = NSMenu()

        // Header
        let titleItem = NSMenuItem(title: "LidMotion", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        // Lettura angolo live
        angleMenuItem = NSMenuItem(title: "Lid: Initializing...", action: nil, keyEquivalent: "")
        angleMenuItem.isEnabled = false
        menu.addItem(angleMenuItem)

        // Avviso permesso mancante
        permissionMenuItem = NSMenuItem(title: "⚠️ Screen Recording Permission Required", action: #selector(checkPermissions), keyEquivalent: "")
        permissionMenuItem.isHidden = AppState.shared.hasScreenRecordingPermission
        menu.addItem(permissionMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Toggle attivo/disattivo
        let isEnabled = PreferencesManager.shared.isEnabled
        enabledMenuItem = NSMenuItem(title: "Effect Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledMenuItem.state = isEnabled ? .on : .off
        menu.addItem(enabledMenuItem)

        // Anteprima
        let previewItem = NSMenuItem(title: "Preview Animation", action: #selector(simulateAnimation), keyEquivalent: "p")
        menu.addItem(previewItem)

        menu.addItem(NSMenuItem.separator())

        // Launch at login
        launchAtLoginMenuItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginMenuItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchAtLoginMenuItem)

        // Impostazioni
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Esci
        let quitItem = NSMenuItem(title: "Quit LidMotion", action: #selector(quitApp), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private var lastMenuUpdate = Date.distantPast

    private func setupSensor() {
        let sensor = LidAngleSensor.shared

        sensor.onAngle = { [weak self] angle in
            guard let self = self else { return }
            
            // Passa al controller se l'effetto è abilitato
            if PreferencesManager.shared.isEnabled {
                self.controller.handle(angle: angle)
            }

            // Throttle aggiornamento UI
            let now = Date()
            if now.timeIntervalSince(self.lastMenuUpdate) > 0.25 {
                self.lastMenuUpdate = now
                self.angleMenuItem.title = String(format: "Lid: %.1f°", angle)
                self.permissionMenuItem.isHidden = AppState.shared.hasScreenRecordingPermission
                self.settingsController?.updateLive(angle: angle, reference: self.controller.reference)
            }
        }

        sensor.start()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self, !sensor.isAvailable else { return }
            self.angleMenuItem.title = "Hinge sensor not found"
            AppState.shared.isSensorAvailable = false
        }
    }

    private func observeSystemEvents() {
        let workspace = NSWorkspace.shared.notificationCenter
        let names: [Notification.Name] = [
            NSWorkspace.willSleepNotification,
            NSWorkspace.didWakeNotification,
            NSWorkspace.screensDidSleepNotification,
            NSWorkspace.screensDidWakeNotification,
            NSWorkspace.sessionDidResignActiveNotification
        ]
        for name in names {
            workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.controller.reset()
            }
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            self?.controller.reset()
        }
    }

    @objc private func toggleEnabled() {
        let newVal = !PreferencesManager.shared.isEnabled
        PreferencesManager.shared.isEnabled = newVal
        enabledMenuItem.state = newVal ? .on : .off
        if !newVal {
            controller.reset()
        }
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                launchAtLoginMenuItem.state = .off
            } else {
                try SMAppService.mainApp.register()
                launchAtLoginMenuItem.state = .on
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }
    }

    @objc private func simulateAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.controller.runPreview()
        }
    }

    @objc private func openSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController(onPreview: { [weak self] in
                self?.controller.runPreview()
            })
        }
        settingsController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func checkPermissions() {
        AppState.shared.requestPermissions()
    }

    @objc private func quitApp() {
        LidAngleSensor.shared.stop()
        controller?.reset()
        NSApp.terminate(nil)
    }
}
