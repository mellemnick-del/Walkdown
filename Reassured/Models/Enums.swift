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
        case .pass: Theme.calmGreen
        case .partial: Theme.calmAmber
        case .fail: Theme.calmCoral
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
        case .critical: Theme.calmPlum
        case .high: Theme.calmCoral
        case .medium: Theme.calmAmber
        case .low: Theme.calmBlue
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
    /// In Recently Deleted. Hidden everywhere, removed for good after 30 days.
    case deleted

    var id: String { rawValue }

    /// The statuses shown as filters on the Audits list.
    static let listed: [AuditStatus] = [.inProgress, .complete, .archived]

    var label: String {
        switch self {
        case .inProgress: "In Progress"
        case .complete: "Complete"
        case .archived: "Archived"
        case .deleted: "Recently Deleted"
        }
    }
}

/// Whether the audit is done on site or as a self-assessment.
enum AuditKind: String, Codable, CaseIterable, Identifiable {
    case onSite, selfAssessment

    var id: String { rawValue }

    var label: String {
        switch self {
        case .onSite: "On-Site Audit"
        case .selfAssessment: "Self-Assessment"
        }
    }

    var reportTitle: String {
        switch self {
        case .onSite: "Security Audit Report"
        case .selfAssessment: "Security Self-Assessment"
        }
    }
}
