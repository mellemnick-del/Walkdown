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
    var kindRaw: String = AuditKind.onSite.rawValue

    /// The client organization this audit is for, if any. The inverse is declared on Client.
    var client: Client?
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \ControlResult.audit)
    var controls: [ControlResult]? = []

    @Relationship(deleteRule: .cascade, inverse: \Finding.audit)
    var findings: [Finding]? = []

    @Relationship(deleteRule: .cascade, inverse: \RemediationTask.audit)
    var tasks: [RemediationTask]? = []

    init(clientName: String, siteName: String = "", location: String = "", auditorName: String = "",
         date: Date = .now, scopeNotes: String = "", checklistName: String, kind: AuditKind = .onSite) {
        self.clientName = clientName
        self.siteName = siteName
        self.location = location
        self.auditorName = auditorName
        self.date = date
        self.scopeNotes = scopeNotes
        self.checklistName = checklistName
        self.kindRaw = kind.rawValue
    }

    var status: AuditStatus {
        get { AuditStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }

    var kind: AuditKind {
        get { AuditKind(rawValue: kindRaw) ?? .onSite }
        set { kindRaw = newValue.rawValue }
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

    var openTasks: [RemediationTask] {
        (tasks ?? []).filter { !$0.isDone }.sorted(by: RemediationTask.nextUp)
    }

    /// Most recent change to any control, used to pick the audit shown on Home.
    var lastActivity: Date {
        (controls ?? []).map(\.updatedAt).max() ?? createdAt
    }

    var totalCount: Int { controls?.count ?? 0 }

    var answeredCount: Int { (controls ?? []).filter { $0.status != .notStarted }.count }

    var progress: Double { totalCount == 0 ? 0 : Double(answeredCount) / Double(totalCount) }

    func count(_ status: ControlStatus) -> Int {
        (controls ?? []).filter { $0.status == status }.count
    }

    /// How many scored answers (Pass, Partial, or Fail) an audit needs before it shows a score.
    static let minimumScoredAnswers = 5

    /// Compliance score from 0 to 1. Pass counts fully, partial counts half, N/A and unanswered are left out.
    /// Nil until enough controls are answered for the number to mean something
    /// (5, or every scorable control on a very short checklist).
    var score: Double? {
        let controls = controls ?? []
        let scored = controls.filter { [.pass, .partial, .fail].contains($0.status) }.count
        let scorable = controls.filter { $0.status != .notApplicable }.count
        guard scored > 0, scored >= min(Self.minimumScoredAnswers, scorable) else { return nil }
        return ComplianceScore.score(for: controls)
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
