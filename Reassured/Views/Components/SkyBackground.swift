import SwiftUI

/// Home's background follows the real sky: soft peach at dawn, clear blue by day, warm lavender
/// at dusk, and stars at night. Light mode stays bright and airy; dark mode stays a deep night sky.
struct SkyBackground: View {
    @Environment(\.colorScheme) private var scheme

    enum Phase {
        case dawn, day, dusk, night

        init(date: Date) {
            switch Calendar.current.component(.hour, from: date) {
            case 5..<9: self = .dawn
            case 9..<17: self = .day
            case 17..<20: self = .dusk
            default: self = .night
            }
        }
    }

    var body: some View {
        // Re-check the time every few minutes so the sky changes while the app is open.
        TimelineView(.periodic(from: .now, by: 300)) { context in
            let phase = Phase(date: context.date)
            ZStack {
                LinearGradient(colors: colors(for: phase), startPoint: .top, endPoint: .bottom)
                if phase == .dawn || phase == .dusk {
                    RadialGradient(colors: [glow(for: phase), .clear], center: .init(x: 0.5, y: 0.0),
                                   startRadius: 10, endRadius: 420)
                        .blendMode(scheme == .dark ? .screen : .normal)
                }
                if scheme == .dark && phase != .day {
                    StarField(density: phase == .night ? 1 : 0.4)
                }
            }
            .animation(.easeInOut(duration: 2), value: phase)
        }
        .ignoresSafeArea()
    }

    private func colors(for phase: Phase) -> [Color] {
        let hex: [UInt32]
        switch (phase, scheme == .dark) {
        case (.dawn, false): hex = [0xF8DCC6, 0xEFE8EA, 0xFBF7F0]
        case (.day, false): hex = [0xD6EAF4, 0xE9F2F4, 0xFBF7F0]
        case (.dusk, false): hex = [0xF2CDB2, 0xE6DAEA, 0xFBF7F0]
        case (.night, false): hex = [0xDCE2F2, 0xEAEDF4, 0xFBF7F0]
        case (.dawn, true): hex = [0x1A2C52, 0x0D1B36, 0x081224]
        case (.day, true): hex = [0x12305A, 0x0C1E3C, 0x081224]
        case (.dusk, true): hex = [0x2A2650, 0x0F1C3A, 0x081224]
        case (.night, true): hex = [0x060E20, 0x081430, 0x081224]
        }
        return hex.map { Color(uiColor: Self.rgb($0)) }
    }

    private func glow(for phase: Phase) -> Color {
        switch phase {
        case .dawn: Color(uiColor: Self.rgb(0xFFD98A)).opacity(scheme == .dark ? 0.25 : 0.45)
        case .dusk: Color(uiColor: Self.rgb(0xF0A07A)).opacity(scheme == .dark ? 0.22 : 0.4)
        default: .clear
        }
    }

    private static func rgb(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

/// A quiet field of stars in fixed positions, some gently twinkling.
private struct StarField: View {
    let density: Double
    @State private var twinkle = false

    private struct Star { let x, y, size, base: Double; let twinkles: Bool }

    // Seeded so the stars stay in the same place every time.
    private static let stars: [Star] = {
        var seed: UInt64 = 0x5EED
        func next() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 33) / Double(UInt64(1) << 31)
        }
        return (0..<70).map { index in
            Star(x: next(), y: next() * 0.7, size: 1 + next() * 1.8, base: 0.35 + next() * 0.5, twinkles: index % 5 == 0)
        }
    }()

    var body: some View {
        GeometryReader { proxy in
            ForEach(Array(Self.stars.prefix(Int(Double(Self.stars.count) * density)).enumerated()), id: \.offset) { _, star in
                Circle()
                    .fill(.white)
                    .frame(width: star.size, height: star.size)
                    .opacity(star.twinkles && twinkle ? star.base * 0.3 : star.base)
                    .position(x: star.x * proxy.size.width, y: star.y * proxy.size.height)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { twinkle = true }
        }
        .accessibilityHidden(true)
    }
}
