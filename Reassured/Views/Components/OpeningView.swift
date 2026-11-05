import SwiftUI

/// Picks up exactly where the launch screen leaves off (same art, same spot). Then the morning
/// arrives: soft sun rays fan out and slowly turn, the glow breathes, a few motes of light drift
/// up, the sun lifts, and the name rises in before the app appears. Tap to skip.
/// With Reduce Motion on, the light fades in without the movement.
struct OpeningView: View {
    let finished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lift = false
    @State private var glow = false
    @State private var breathe = false
    @State private var turn = false
    @State private var showName = false

    /// Where the sun sits relative to the screen's center once it has lifted.
    private let sunOffset: CGFloat = -29

    var body: some View {
        ZStack {
            Theme.navy
            // The launch art at its natural size, centered, exactly as iOS shows it at launch.
            Image("LaunchArt")
                .fixedSize()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            // Sun rays, slowly turning, like light through morning haze.
            SunRays(count: 14)
                .fill(RadialGradient(colors: [Theme.sunriseLight.opacity(0.55), Theme.sunrise.opacity(0.18), .clear],
                                     center: .center, startRadius: 30, endRadius: 260))
                .frame(width: 560, height: 560)
                .blur(radius: 8)
                .rotationEffect(.degrees(turn ? 40 : 0))
                .scaleEffect(glow ? 1 : 0.6)
                .opacity(glow ? 1 : 0)
                .offset(y: sunOffset)
                .blendMode(.screen)

            // A warm halo that gently breathes.
            Circle()
                .fill(Theme.sunrise.opacity(glow ? (breathe ? 0.42 : 0.3) : 0))
                .frame(width: 300, height: 300)
                .scaleEffect(breathe ? 1.12 : 1)
                .blur(radius: 70)
                .offset(y: sunOffset - 11)

            if glow && !reduceMotion {
                LightMotes(count: 22, duration: 2.6)
                    .opacity(0.75)
                    .transition(.opacity)
            }

            ReassuredMark(size: 170, sunProgress: lift ? 1.12 : 1)
                .scaleEffect(lift ? 1.04 : 1)
            Text("Reassured")
                .font(.system(size: 36, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .shadow(color: Theme.navy.opacity(0.4), radius: 8, y: 2)
                .opacity(showName ? 1 : 0)
                .offset(y: showName ? 125 : 140)
        }
        // Center on the whole screen, as the launch screen does, so nothing jumps.
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture(perform: finished)
        .task {
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.easeInOut(duration: 0.9)) {
                glow = true
                lift = true
            }
            if !reduceMotion {
                withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) { turn = true }
                withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { breathe = true }
            }
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) { showName = true }
            try? await Task.sleep(for: .seconds(1.4))
            finished()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reassured")
    }
}

/// Thin, tapering wedges radiating from the center, alternating long and short.
struct SunRays: Shape {
    var count: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for index in 0..<count {
            let angle = Double(index) / Double(count) * 2 * .pi
            let halfWidth = .pi / Double(count) * 0.32
            let length = radius * (index.isMultiple(of: 2) ? 1 : 0.72)
            func point(_ a: Double, _ r: CGFloat) -> CGPoint {
                CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r)
            }
            path.move(to: point(angle, 26))
            path.addLine(to: point(angle - halfWidth, length))
            path.addLine(to: point(angle + halfWidth, length))
            path.closeSubpath()
        }
        return path
    }
}
