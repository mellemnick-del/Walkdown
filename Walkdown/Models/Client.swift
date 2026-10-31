import Foundation
import SwiftData

/// A client organization an assessor or MSP works for. Groups audits and evidence so
/// one client's documents are never suggested in another client's audit.
/// Maps to a synced client organization once accounts exist (see docs/ACCOUNTS_PLAN.md).
@Model
final class Client {
    var id: UUID = UUID()
    var name: String = ""
    var industry: String = ""
    var contactName: String = ""
    var contactEmail: String = ""
    var notes: String = ""
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .nullify, inverse: \Audit.client)
    var audits: [Audit]? = []

    @Relationship(deleteRule: .nullify, inverse: \LockerItem.client)
    var lockerItems: [LockerItem]? = []

    init(name: String, industry: String = "") {
        self.name = name
        self.industry = industry
    }

    var sortedAudits: [Audit] {
        (audits ?? []).sorted { $0.date > $1.date }
    }

    var openTaskCount: Int {
        (audits ?? []).reduce(0) { $0 + $1.openTasks.count }
    }

    /// Score of the most recent audit that has results.
    var latestScore: Double? {
        sortedAudits.lazy.compactMap(\.score).first
    }
}
