import SwiftUI

/// The short opening animation: the cradle draws in, the sun rises into it and glows,
/// then the app appears. Tap anywhere to skip.
struct OpeningView: View {
    let finished: () -> Void

    @State private var cradle: Double = 0
    @State private var sun: Double = 0
    @State private var glow = false
    @State private var showName = false

    var body: some View {
        ZStack {
            Theme.dusk.ignoresSafeArea()
            Circle()
                .fill(Theme.sunrise.opacity(glow ? 0.28 : 0))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(y: -30)
            VStack(spacing: 22) {
                ReassuredMark(size: 170, sunProgress: sun, cradleProgress: cradle)
                Text("Reassured")
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .opacity(showName ? 1 : 0)
                    .offset(y: showName ? 0 : 8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: finished)
        .task {
            withAnimation(.easeInOut(duration: 0.55)) { cradle = 1 }
            try? await Task.sleep(for: .seconds(0.35))
            withAnimation(.spring(response: 0.9, dampingFraction: 0.8)) { sun = 1 }
            try? await Task.sleep(for: .seconds(0.45))
            withAnimation(.easeOut(duration: 0.6)) {
                glow = true
                showName = true
            }
            try? await Task.sleep(for: .seconds(0.9))
            finished()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reassured")
    }
}
