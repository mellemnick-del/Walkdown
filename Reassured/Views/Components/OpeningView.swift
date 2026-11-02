import SwiftUI

/// Picks up exactly where the launch screen leaves off (same art, same spot), then the glow
/// brightens, the sun lifts, and the name rises in before the app appears. Tap to skip.
struct OpeningView: View {
    let finished: () -> Void

    @State private var lift = false
    @State private var glow = false
    @State private var showName = false

    var body: some View {
        ZStack {
            Theme.navy
            // The launch art at its natural size, centered, exactly as iOS shows it at launch.
            Image("LaunchArt")
                .fixedSize()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            Circle()
                .fill(Theme.sunrise.opacity(glow ? 0.35 : 0))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(y: -40)
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
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) { showName = true }
            try? await Task.sleep(for: .seconds(1.1))
            finished()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reassured")
    }
}
