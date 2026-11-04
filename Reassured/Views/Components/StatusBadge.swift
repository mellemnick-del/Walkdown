import SwiftUI

struct StatusIcon: View {
    let status: ControlStatus

    var body: some View {
        Image(systemName: status.symbol)
            .foregroundStyle(status.color)
            .font(.title3)
            .contentTransition(.symbolEffect(.replace))
            .symbolEffect(.bounce, value: status)
            .accessibilityLabel(status.label)
    }
}

struct SeverityBadge: View {
    let severity: Severity

    var body: some View {
        Text(severity.label)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(severity.color.opacity(0.15), in: Capsule())
            .foregroundStyle(severity.color)
    }
}
