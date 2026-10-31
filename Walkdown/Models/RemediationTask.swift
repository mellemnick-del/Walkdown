import Foundation
import SwiftData

enum TaskState: String, Codable, CaseIterable, Identifiable {
    case open, inProgress, done

    var id: String { rawValue }

    var label: String {
        switch self {
        case .open: "Open"
        case .inProgress: "In Progress"
        case .done: "Done"
        }
    }
}

/// A fix to make, usually created from a failed or partial control.
@Model
final class RemediationTask {
    var title: String = ""
    var detail: String = ""
    var owner: String = ""
    var dueDate: Date?
    var priorityRaw: String = Severity.medium.rawValue
    var stateRaw: String = TaskState.open.rawValue
    var createdAt: Date = Date.now
    var completedAt: Date?

    var audit: Audit?
    var control: ControlResult?

    init(title: String, detail: String = "", owner: String = "", dueDate: Date? = nil, priority: Severity = .medium) {
        self.title = title
        self.detail = detail
        self.owner = owner
        self.dueDate = dueDate
        self.priorityRaw = priority.rawValue
    }

    var priority: Severity {
        get { Severity(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    var state: TaskState {
        get { TaskState(rawValue: stateRaw) ?? .open }
        set {
            stateRaw = newValue.rawValue
            completedAt = newValue == .done ? .now : nil
        }
    }

    var isDone: Bool { state == .done }

    var isOverdue: Bool {
        guard !isDone, let dueDate else { return false }
        return dueDate < Calendar.current.startOfDay(for: .now)
    }

    /// Overdue first, then by due date, then by priority.
    static func nextUp(_ a: RemediationTask, _ b: RemediationTask) -> Bool {
        if a.isOverdue != b.isOverdue { return a.isOverdue }
        switch (a.dueDate, b.dueDate) {
        case let (x?, y?) where x != y: return x < y
        case (.some, .none): return true
        case (.none, .some): return false
        default: return a.priority.rank < b.priority.rank
        }
    }
}

extension Severity {
    /// Suggested days to fix, used when a remediation plan is generated.
    var suggestedDays: Int {
        switch self {
        case .critical: 7
        case .high: 30
        case .medium: 60
        case .low: 90
        }
    }
}
