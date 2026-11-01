import Foundation

/// UserDefaults keys shared across screens.
enum SettingsKeys {
    static let auditorName = "auditorName"
    static let companyName = "companyName"
    static let requireFaceID = "requireFaceID"
}

extension SettingsKeys {
    static let helpEmail = "helpEmail"
}

extension SettingsKeys {
    static let hasOnboarded = "hasOnboarded"
    static let userRole = "userRole"
}

/// Who is using the app. Changes defaults and wording, never what features are available.
enum UserRole: String, CaseIterable, Identifiable {
    case organization, assessor

    var id: String { rawValue }

    var label: String {
        switch self {
        case .organization: "My Organization"
        case .assessor: "I'm an Assessor"
        }
    }

    var detail: String {
        switch self {
        case .organization: "Assess your own security, fix the gaps, and keep your evidence ready for auditors."
        case .assessor: "Run audits for clients on site, capture evidence, and deliver professional reports."
        }
    }

    var symbol: String {
        switch self {
        case .organization: "building.2.crop.circle"
        case .assessor: "person.badge.shield.checkmark"
        }
    }

    var defaultAuditKind: AuditKind {
        self == .organization ? .selfAssessment : .onSite
    }
}
