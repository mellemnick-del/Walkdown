import Foundation
import SwiftData

/// An issue written up for the report, usually tied to a failed control.
@Model
final class Finding {
    var title: String = ""
    var detail: String = ""
    var recommendation: String = ""
    var severityRaw: String = Severity.medium.rawValue
    var createdAt: Date = Date.now

    var audit: Audit?
    var control: ControlResult?

    init(title: String, detail: String = "", recommendation: String = "", severity: Severity = .medium) {
        self.title = title
        self.detail = detail
        self.recommendation = recommendation
        self.severityRaw = severity.rawValue
    }

    var severity: Severity {
        get { Severity(rawValue: severityRaw) ?? .medium }
        set { severityRaw = newValue.rawValue }
    }
}
