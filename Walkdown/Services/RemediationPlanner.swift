import Foundation
import SwiftData

enum RemediationPlanner {
    /// Creates a task for every failed or partial control that doesn't already have an open one.
    /// Priority comes from the worst linked finding, or Fail = High and Partial = Medium.
    @discardableResult
    static func buildPlan(for audit: Audit, in context: ModelContext) -> Int {
        var created = 0
        for control in audit.sortedControls where control.status == .fail || control.status == .partial {
            let hasOpenTask = (control.tasks ?? []).contains { !$0.isDone }
            guard !hasOpenTask else { continue }
            let priority = suggestedPriority(for: control)
            let due = Calendar.current.date(byAdding: .day, value: priority.suggestedDays, to: .now)
            var detail = "Goal: \(control.guidance)"
            if !control.notes.isEmpty { detail += "\n\nWhat the audit found: \(control.notes)" }
            let task = RemediationTask(title: "Fix: \(control.title)", detail: detail, dueDate: due, priority: priority)
            context.insert(task)
            task.audit = audit
            task.control = control
            created += 1
        }
        return created
    }

    static func suggestedPriority(for control: ControlResult) -> Severity {
        if let worst = (control.findings ?? []).min(by: { $0.severity.rank < $1.severity.rank }) {
            return worst.severity
        }
        return control.status == .fail ? .high : .medium
    }
}
