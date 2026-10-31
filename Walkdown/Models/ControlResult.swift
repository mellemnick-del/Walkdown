import Foundation
import SwiftData

/// One checklist item inside an audit, copied from a template when the audit is created.
@Model
final class ControlResult {
    var controlID: String = ""
    var title: String = ""
    var guidance: String = ""
    var groupName: String = ""
    var groupOrder: Int = 0
    var order: Int = 0
    var statusRaw: String = ControlStatus.notStarted.rawValue
    var notes: String = ""
    var updatedAt: Date = Date.now

    var audit: Audit?

    @Relationship(deleteRule: .cascade, inverse: \Evidence.control)
    var evidence: [Evidence]? = []

    @Relationship(deleteRule: .nullify, inverse: \Finding.control)
    var findings: [Finding]? = []

    init(controlID: String, title: String, guidance: String, groupName: String, groupOrder: Int, order: Int) {
        self.controlID = controlID
        self.title = title
        self.guidance = guidance
        self.groupName = groupName
        self.groupOrder = groupOrder
        self.order = order
    }

    var status: ControlStatus {
        get { ControlStatus(rawValue: statusRaw) ?? .notStarted }
        set {
            statusRaw = newValue.rawValue
            updatedAt = .now
        }
    }

    var sortedEvidence: [Evidence] {
        (evidence ?? []).sorted { $0.createdAt < $1.createdAt }
    }
}
