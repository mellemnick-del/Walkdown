import SwiftUI

/// The rounded card used across Home and dashboards.
struct Card<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(cornerRadius: 18)
    }
}

extension View {
    /// Frosted Liquid Glass over the sky on iOS 26, a soft solid card on earlier versions.
    @ViewBuilder
    func cardSurface(cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self
                .background(Theme.card, in: shape)
                .shadow(color: Theme.navy.opacity(0.06), radius: 8, y: 3)
        }
    }
}

struct SectionTitle: View {
    let title: String
    var actionLabel: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title).font(.system(.title3, design: .serif).weight(.semibold))
            Spacer()
            if let actionLabel, let action {
                Button(actionLabel, action: action).font(.subheadline)
            }
        }
        .padding(.top, 8)
    }
}

/// A large score ring with the percentage in the middle. Fills in with an animation.
struct ScoreRing: View {
    let score: Double?
    var size: CGFloat = 120
    var lineWidth: CGFloat = 12
    /// White text and track, for use on the dusk gradient.
    var onDark = false

    @State private var shown: Double = 0
    @State private var glowing = false
    @State private var crossed = 0

    private var color: Color {
        guard let score else { return .secondary }
        switch score {
        case 0.8...: return Theme.calmGreen
        case 0.5..<0.8: return onDark ? Theme.sunrise : Theme.calmAmber
        default: return Theme.calmCoral
        }
    }

    var body: some View {
        ZStack {
            Circle().stroke((onDark ? Color.white : Color.secondary).opacity(onDark ? 0.18 : 0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: shown)
                .stroke(color.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(score.map { "\(Int(($0 * 100).rounded()))" } ?? "--")
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("score")
                    .font(.caption)
                    .foregroundStyle(onDark ? Color.white.opacity(0.75) : Color.secondary)
            }
            .foregroundStyle(onDark ? Color.white : Color.primary)
        }
        .frame(width: size, height: size)
        .background {
            Circle()
                .fill(Theme.sunrise)
                .blur(radius: size * 0.18)
                .opacity(glowing ? 0.55 : 0)
                .scaleEffect(glowing ? 1.1 : 0.9)
        }
        .sensoryFeedback(.success, trigger: crossed)
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.1)) { shown = score ?? 0 }
            if (score ?? 0) >= 0.8 { pulse(after: 0.9) }
        }
        .onChange(of: score) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.5)) { shown = newValue ?? 0 }
            if (oldValue ?? 0) < 0.8 && (newValue ?? 0) >= 0.8 {
                crossed += 1
                pulse(after: 0.4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(score.map { "Score \(Int(($0 * 100).rounded())) percent" } ?? "No score yet")
    }

    /// One soft gold glow: a small celebration for a strong score.
    private func pulse(after delay: Double) {
        Task {
            try? await Task.sleep(for: .seconds(delay))
            withAnimation(.easeOut(duration: 0.6)) { glowing = true }
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeIn(duration: 0.9)) { glowing = false }
        }
    }
}
