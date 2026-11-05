import Foundation
import WidgetKit

/// Keeps the widgets' summary current. Called whenever audits or tasks change.
enum WidgetUpdater {
    private static var last: WidgetSnapshot?

    static func update(audits: [Audit], tasks: [RemediationTask]) {
        let live = audits.filter { !$0.isInTrash }
        let focus = live.filter { $0.status == .inProgress }.max { $0.lastActivity < $1.lastActivity }
        let open = tasks
            .filter { !$0.isDone && !($0.audit?.isInTrash ?? false) }
            .sorted(by: RemediationTask.nextUp)
        let snapshot = WidgetSnapshot(
            auditName: focus?.displayName,
            checklist: focus?.checklistName,
            score: focus?.score,
            answered: focus?.answeredCount ?? 0,
            total: focus?.totalCount ?? 0,
            openTasks: open.count,
            overdue: open.filter(\.isOverdue).count,
            nextTasks: open.prefix(3).map {
                WidgetSnapshot.TaskLine(title: $0.title, priority: $0.priority.label, due: $0.dueDate, overdue: $0.isOverdue)
            },
            updatedAt: .now)
        // Only write and reload when something the widget shows has changed.
        var comparable = snapshot
        comparable.updatedAt = last?.updatedAt ?? snapshot.updatedAt
        guard comparable != last else { return }
        last = snapshot
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
