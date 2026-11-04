import SwiftUI
import UIKit

/// Golden motes of light drifting upward, like dust in morning sun. Reassured's calm take on confetti.
struct LightMotes: View {
    var count = 46
    var duration: Double = 3.2

    private struct Mote {
        let x: Double, size: Double, delay: Double, speed: Double, sway: Double, color: Int
    }

    private let motes: [Mote]
    @State private var start = Date.now

    init(count: Int = 46, duration: Double = 3.2) {
        self.count = count
        self.duration = duration
        var seed: UInt64 = 0xC0FFEE
        func next() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 33) / Double(UInt64(1) << 31)
        }
        motes = (0..<count).map { _ in
            Mote(x: next(), size: 3 + next() * 7, delay: next() * 0.9, speed: 0.55 + next() * 0.6,
                 sway: (next() - 0.5) * 60, color: Int(next() * 3))
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(start)
                for mote in motes {
                    let t = (elapsed - mote.delay) / duration * mote.speed
                    guard t > 0, t < 1 else { continue }
                    let y = size.height * (1.05 - t * 1.1)
                    let x = mote.x * size.width + sin(t * .pi * 2) * mote.sway
                    let fade = t < 0.15 ? t / 0.15 : (1 - t) / 0.85
                    let rect = CGRect(x: x, y: y, width: mote.size, height: mote.size)
                    let color: Color = [Theme.sunrise, Theme.sunriseLight, Color(red: 1, green: 0.78, blue: 0.6)][mote.color]
                    // Each mote gets its own copy so blur and opacity don't stack up.
                    var mote2D = context
                    mote2D.opacity = fade * 0.9
                    mote2D.addFilter(.blur(radius: mote.size * 0.25))
                    mote2D.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A number that counts up when its value changes inside an animation.
struct CountingText: View, Animatable {
    var value: Double
    var font: Font

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text("\(Int(value.rounded()))")
            .font(font)
            .monospacedDigit()
    }
}

/// Buttons that press in slightly, like real buttons.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

enum Haptics {
    /// Three soft taps building into a success, timed with a celebration.
    static func drumroll() {
        Task { @MainActor in
            for intensity in [0.35, 0.55, 0.75] {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: intensity)
                try? await Task.sleep(for: .milliseconds(160))
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
