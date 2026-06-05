import UIKit
import CoreHaptics

enum Haptics {
    static func tap(_ intensity: CGFloat = 0.4) {
        let g = UIImpactFeedbackGenerator(style: .soft)
        g.prepare()
        g.impactOccurred(intensity: intensity)
    }

    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.success)
    }

    // MARK: - Pulse-flavoured patterns via CHHapticEngine

    static func scanStart() { PulseHapticEngine.shared.playScanStart() }
    static func scanComplete() { PulseHapticEngine.shared.playScanComplete() }
}

final class PulseHapticEngine {
    static let shared = PulseHapticEngine()

    private var engine: CHHapticEngine?
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private init() { spin() }

    private func spin() {
        guard supportsHaptics else { return }
        do {
            let e = try CHHapticEngine()
            e.resetHandler = { [weak self] in self?.spin() }
            try e.start()
            engine = e
        } catch {
            engine = nil
        }
    }

    // Soft thump as the scan begins.
    func playScanStart() {
        play(events: [
            transient(time: 0, intensity: 0.65, sharpness: 0.45)
        ])
    }

    // Two short ticks + a smooth tail, like a confirmation chime.
    func playScanComplete() {
        play(events: [
            transient(time: 0.00, intensity: 0.55, sharpness: 0.65),
            transient(time: 0.10, intensity: 0.85, sharpness: 0.55),
            continuous(time: 0.18, duration: 0.32, intensity: 0.45, sharpness: 0.35)
        ])
    }

    // MARK: - Helpers

    private func transient(time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            .init(parameterID: .hapticIntensity, value: intensity),
            .init(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: time)
    }

    private func continuous(time: TimeInterval, duration: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticContinuous, parameters: [
            .init(parameterID: .hapticIntensity, value: intensity),
            .init(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: time, duration: duration)
    }

    private func play(events: [CHHapticEvent]) {
        guard let engine, supportsHaptics else {
            // Fallback to the basic generator so simulator / older hardware still gets a thump.
            Haptics.tap(0.5)
            return
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            Haptics.tap(0.5)
        }
    }
}
