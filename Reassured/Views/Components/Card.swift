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
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct SectionTitle: View {
    let title: String
    var actionLabel: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title).font(.title3.bold())
            Spacer()
            if let actionLabel, let action {
                Button(actionLabel, action: action).font(.subheadline)
            }
        }
        .padding(.top, 8)
    }
}

/// A large score ring with the percentage in the middle.
struct ScoreRing: View {
    let score: Double?
    var size: CGFloat = 120
    var lineWidth: CGFloat = 12

    private var color: Color {
        guard let score else { return .secondary }
        switch score {
        case 0.8...: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            Circle().stroke(Color.secondary.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: score ?? 0)
                .stroke(color.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: score)
            VStack(spacing: 0) {
                Text(score.map { "\(Int(($0 * 100).rounded()))" } ?? "--")
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("score")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(score.map { "Score \(Int(($0 * 100).rounded())) percent" } ?? "No score yet")
    }
}
