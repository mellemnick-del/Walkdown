import Foundation
import SwiftData

enum AuditFactory {
    /// Creates an audit and copies every template item into it as a control.
    @discardableResult
    static func create(from template: ChecklistTemplate, clientName: String, siteName: String, location: String,
                       auditorName: String, date: Date, scopeNotes: String, in context: ModelContext) -> Audit {
        let audit = Audit(clientName: clientName, siteName: siteName, location: location, auditorName: auditorName,
                          date: date, scopeNotes: scopeNotes, checklistName: template.name)
        context.insert(audit)
        for (groupIndex, group) in template.groups.enumerated() {
            for (itemIndex, item) in group.items.enumerated() {
                let control = ControlResult(controlID: item.id, title: item.title, guidance: item.guidance,
                                            groupName: group.name, groupOrder: groupIndex, order: itemIndex)
                context.insert(control)
                control.audit = audit
            }
        }
        return audit
    }
}
