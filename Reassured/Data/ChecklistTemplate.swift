import Foundation

/// The audit areas checklists are grouped under in the library.
enum ChecklistArea: String, CaseIterable, Identifiable {
    case general, defense, federal, lawEnforcement, tax, healthcare, payments, serviceOrgs, privacy

    var id: String { rawValue }

    var label: String {
        switch self {
        case .general: "General and IT Controls"
        case .defense: "Defense Contractors"
        case .federal: "Federal Systems"
        case .lawEnforcement: "Law Enforcement"
        case .tax: "Tax Data"
        case .healthcare: "Healthcare"
        case .payments: "Payments"
        case .serviceOrgs: "Service Organizations"
        case .privacy: "Privacy"
        }
    }

    var symbol: String {
        switch self {
        case .general: "building.2"
        case .defense: "shield.lefthalf.filled"
        case .federal: "building.columns"
        case .lawEnforcement: "star.circle"
        case .tax: "doc.text.magnifyingglass"
        case .healthcare: "cross.case"
        case .payments: "creditcard"
        case .serviceOrgs: "server.rack"
        case .privacy: "hand.raised"
        }
    }
}

/// A read-only checklist an audit is built from.
struct ChecklistTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let area: ChecklistArea
    let summary: String
    let source: String
    let groups: [TemplateGroup]

    var itemCount: Int { groups.reduce(0) { $0 + $1.items.count } }
}

struct TemplateGroup: Hashable {
    let name: String
    let items: [TemplateItem]
}

struct TemplateItem: Hashable {
    let id: String
    let title: String
    let guidance: String

    init(id: String, title: String, guidance: String) {
        self.id = id
        self.title = title
        self.guidance = guidance
    }

    /// Short form used by the larger checklists: ID, title, guidance.
    init(_ id: String, _ title: String, _ guidance: String) {
        self.init(id: id, title: title, guidance: guidance)
    }
}

enum TemplateLibrary {
    static let all: [ChecklistTemplate] = [
        physicalWalkdown, itGeneralControls, nistCSF,
        cmmcLevel1, cmmcLevel2,
        nist80053,
        hipaaSecurity,
        pciDSS,
        soc2Readiness,
        gdpr,
    ]

    static func template(id: String) -> ChecklistTemplate? {
        all.first { $0.id == id }
    }

    static func templates(in area: ChecklistArea) -> [ChecklistTemplate] {
        all.filter { $0.area == area }
    }
}
