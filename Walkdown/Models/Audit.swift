import Foundation
import SwiftData

@Model
final class Audit {
    var id: UUID = UUID()
    var clientName: String = ""
    var siteName: String = ""
    var location: String = ""
    var auditorName: String = ""
    var date: Date = Date.now
    var scopeNotes: String = ""
    var checklistName: String = ""
    var statusRaw: String = AuditStatus.inProgress.rawValue
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \ControlResult.audit)
    var controls: [ControlResult]? = []

    @Relationship(deleteRule: .cascade, inverse: \Finding.audit)
    var findings: [Finding]? = []

    init(clientName: String, siteName: String = "", location: String = "", auditorName: String = "",
         date: Date = .now, scopeNotes: String = "", checklistName: String) {
        self.clientName = clientName
        self.siteName = siteName
        self.location = location
        self.auditorName = auditorName
        self.date = date
        self.scopeNotes = scopeNotes
        self.checklistName = checklistName
    }

    var status: AuditStatus {
        get { AuditStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }

    /// "Client, Site" or just the client.
    var displayName: String {
        siteName.isEmpty ? clientName : "\(clientName), \(siteName)"
    }

    var sortedControls: [ControlResult] {
        (controls ?? []).sorted { ($0.groupOrder, $0.order) < ($1.groupOrder, $1.order) }
    }

    var sortedFindings: [Finding] {
        (findings ?? []).sorted { ($0.severity.rank, $0.createdAt) < ($1.severity.rank, $1.createdAt) }
    }

    var totalCount: Int { controls?.count ?? 0 }

    var answeredCount: Int { (controls ?? []).filter { $0.status != .notStarted }.count }

    var progress: Double { totalCount == 0 ? 0 : Double(answeredCount) / Double(totalCount) }

    func count(_ status: ControlStatus) -> Int {
        (controls ?? []).filter { $0.status == status }.count
    }

    /// Compliance score from 0 to 1. Pass counts fully, partial counts half, N/A and unanswered are left out.
    var score: Double? {
        ComplianceScore.score(for: controls ?? [])
    }
}

enum ComplianceScore {
    static func score(for controls: [ControlResult]) -> Double? {
        let scored = controls.filter { [.pass, .partial, .fail].contains($0.status) }
        guard !scored.isEmpty else { return nil }
        let points = scored.reduce(0.0) { total, control in
            switch control.status {
            case .pass: total + 1
            case .partial: total + 0.5
            default: total
            }
        }
        return points / Double(scored.count)
    }
}
