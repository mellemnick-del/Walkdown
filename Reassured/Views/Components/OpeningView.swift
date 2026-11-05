import SwiftUI

/// Picks up exactly where the launch screen leaves off (same art, same spot). Then the glow
/// brightens, a soft light gathers beneath the cradle and gently breathes, the sun lifts, and
/// the name rises in before the app appears. Tap to skip. With Reduce Motion on, the glow
/// fades in without breathing.
struct OpeningView: View {
    let finished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lift = false
    @State private var glow = false
    @State private var breathe = false
    @State private var showName = false

    var body: some View {
        ZStack {
            Theme.navy
            // The launch art at its natural size, centered, exactly as iOS shows it at launch.
            Image("LaunchArt")
                .fixedSize()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            // The original halo behind the sun.
            Circle()
                .fill(Theme.sunrise.opacity(glow ? 0.35 : 0))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(y: -40)

            // A soft, warm glow beneath the cradle, like light rising off the horizon. It breathes gently.
            Ellipse()
                .fill(Theme.sunrise.opacity(glow ? (breathe ? 0.3 : 0.2) : 0))
                .frame(width: breathe ? 280 : 240, height: 90)
                .blur(radius: 40)
                .offset(y: 70)

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
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { breathe = true }
            }
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) { showName = true }
            try? await Task.sleep(for: .seconds(1.1))
            finished()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reassured")
    }
}
