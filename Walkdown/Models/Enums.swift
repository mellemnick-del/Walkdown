import SwiftUI

/// The result recorded for a single control during an audit.
enum ControlStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted, pass, partial, fail, notApplicable

    var id: String { rawValue }

    /// The statuses an auditor can pick (everything except "not started").
    static let answerable: [ControlStatus] = [.pass, .partial, .fail, .notApplicable]

    var label: String {
        switch self {
        case .notStarted: "Not Started"
        case .pass: "Pass"
        case .partial: "Partial"
        case .fail: "Fail"
        case .notApplicable: "N/A"
        }
    }

    var symbol: String {
        switch self {
        case .notStarted: "circle"
        case .pass: "checkmark.circle.fill"
        case .partial: "circle.lefthalf.filled"
        case .fail: "xmark.circle.fill"
        case .notApplicable: "minus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .notStarted: .secondary
        case .pass: .green
        case .partial: .orange
        case .fail: .red
        case .notApplicable: .gray
        }
    }
}

/// How serious a finding is. Lower rank sorts first.
enum Severity: String, Codable, CaseIterable, Identifiable {
    case critical, high, medium, low

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    var rank: Int {
        switch self {
        case .critical: 0
        case .high: 1
        case .medium: 2
        case .low: 3
        }
    }

    var color: Color {
        switch self {
        case .critical: .purple
        case .high: .red
        case .medium: .orange
        case .low: .blue
        }
    }

    var uiColor: UIColor {
        switch self {
        case .critical: .systemPurple
        case .high: .systemRed
        case .medium: .systemOrange
        case .low: .systemBlue
        }
    }
}

/// Where an audit sits in its lifecycle.
enum AuditStatus: String, Codable, CaseIterable, Identifiable {
    case inProgress, complete, archived

    var id: String { rawValue }

    var label: String {
        switch self {
        case .inProgress: "In Progress"
        case .complete: "Complete"
        case .archived: "Archived"
        }
    }
}
