import Foundation

/// A read-only checklist an audit is built from.
struct ChecklistTemplate: Identifiable, Hashable {
    let id: String
    let name: String
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
}

enum TemplateLibrary {
    static let all: [ChecklistTemplate] = [physicalWalkdown, nistCSF, hipaaSecurity]

    static func template(id: String) -> ChecklistTemplate? {
        all.first { $0.id == id }
    }
}
