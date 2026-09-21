import Foundation
import IOKit
import IOKit.hid
import QuartzCore

/// Legge il sensore d'angolo della cerniera (HID usage page 0x20, usage 0x8A).
/// Il report 7 fornisce centesimi di grado; il report 1 (gradi interi) è il fallback.
final class LidAngleSensor {
    static let shared = LidAngleSensor()

    /// Chiamato sul main thread con l'angolo del coperchio in gradi.
    var onAngle: ((Double) -> Void)?

    /// Vero se il dispositivo HID della cerniera è stato trovato (aggiornato sul main thread).
    private(set) var isAvailable = false
    /// Vero durante l'anteprima simulata (main thread).
    private(set) var isSimulating = false

    private let queue = DispatchQueue(label: "com.oleoclub.lidmotion.sensor", qos: .userInteractive)
    private var manager: IOHIDManager?
    private var device: IOHIDDevice?
    private var timer: DispatchSourceTimer?
    private var preciseFailures = 0
    private var simulationTimer: DispatchSourceTimer?

    private init() {}

    func start() {
        queue.async { [weak self] in
            guard let self, self.timer == nil else { return }
            if self.device == nil { self.openDevice() }
            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            // Polling a 120Hz per matchare il ProMotion display ed evitare microscatti (stutter)
            timer.schedule(deadline: .now(), repeating: 1.0 / 120.0, leeway: .milliseconds(1))
            timer.setEventHandler { [weak self] in self?.poll() }
            self.timer = timer
            timer.resume()
        }
    }

    func stop() {
        queue.async { [weak self] in
            self?.timer?.cancel()
            self?.timer = nil
        }
    }

    private func openDevice() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(manager, [kIOHIDDeviceUsagePageKey: 0x20, kIOHIDDeviceUsageKey: 0x8A] as CFDictionary)
        guard IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else { return }
        let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> ?? []
        let builtIn = devices.first { (IOHIDDeviceGetProperty($0, "Built-In" as CFString) as? NSNumber)?.boolValue == true }
        guard let device = builtIn ?? devices.first else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            return
        }
        self.manager = manager
        self.device = device
        DispatchQueue.main.async { self.isAvailable = true }
    }

    private var lastDispatchedAngle: Double = -1.0

    private func poll() {
        guard let angle = readAngle() else { return }
        
        // Salta il dispatch sul main thread solo se l'angolo non è cambiato affatto (coperchio fermo).
        // Qualsiasi minimo movimento (risoluzione sensore: 0.01°) viene inviato senza saltare cicli.
        if abs(angle - lastDispatchedAngle) < 0.001 {
            return
        }
        lastDispatchedAngle = angle

        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isSimulating else { return }
            self.onAngle?(angle)
        }
    }

    private func readAngle() -> Double? {
        guard let device else { return nil }
        if preciseFailures < 30 {
            if let raw = readReport(device, id: 7), raw <= 36_000 {
                preciseFailures = 0
                return Double(raw) / 100.0
            }
            preciseFailures += 1
        }
        if let raw = readReport(device, id: 1), raw <= 360 {
            return Double(raw)
        }
        return nil
    }

    private func readReport(_ device: IOHIDDevice, id: UInt8) -> Int? {
        var bytes = [UInt8](repeating: 0, count: 8)
        var length = bytes.count
        let result = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, CFIndex(id), &bytes, &length)
        guard result == kIOReturnSuccess, length >= 3, bytes[0] == id else { return nil }
        return Int(bytes[1]) | (Int(bytes[2]) << 8)
    }

    // MARK: - Anteprima simulata

    /// Simula una chiusura da `start` fino a `bottom` gradi e la riapertura.
    func simulate(from start: Double, to bottom: Double, completion: (() -> Void)? = nil) {
        guard !isSimulating else { return }
        isSimulating = true

        let closeDuration = 1.3, holdDuration = 0.35, openDuration = 1.3
        let begin = CACurrentMediaTime()
        let ease: (Double) -> Double = { x in
            let t = min(1, max(0, x))
            return t * t * (3 - 2 * t)
        }

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 1.0 / 60.0, leeway: .milliseconds(2))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let t = CACurrentMediaTime() - begin
            let angle: Double
            if t < closeDuration {
                angle = start - (start - bottom) * ease(t / closeDuration)
            } else if t < closeDuration + holdDuration {
                angle = bottom
            } else if t < closeDuration + holdDuration + openDuration {
                angle = bottom + (start - bottom) * ease((t - closeDuration - holdDuration) / openDuration)
            } else {
                self.onAngle?(start)
                self.simulationTimer?.cancel()
                self.simulationTimer = nil
                self.isSimulating = false
                completion?()
                return
            }
            self.onAngle?(angle)
        }
        simulationTimer = timer
        timer.resume()
    }
}
