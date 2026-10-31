import Foundation
import UserNotifications

/// Local notifications for evidence expiration and task due dates. Nothing leaves the device.
enum ReminderScheduler {
    private static var center: UNUserNotificationCenter { .current() }

    static func requestPermissionIfNeeded() {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    // MARK: Evidence

    /// Reminds 30 days before, 7 days before, and on the expiration date, at 9 AM.
    static func schedule(_ item: LockerItem) {
        cancel(item)
        guard let expiresAt = item.expiresAt else { return }
        requestPermissionIfNeeded()
        let title = item.title.isEmpty ? "Evidence" : item.title
        for daysBefore in [30, 7, 0] {
            guard let date = Calendar.current.date(byAdding: .day, value: -daysBefore, to: expiresAt) else { continue }
            let body = daysBefore == 0
                ? "\(title) expires today. Upload a current version to stay compliant."
                : "\(title) expires in \(daysBefore) days."
            add(id: "\(item.id.uuidString)-\(daysBefore)", title: "Evidence Expiring", body: body, on: date)
        }
    }

    static func cancel(_ item: LockerItem) {
        center.removePendingNotificationRequests(withIdentifiers: [30, 7, 0].map { "\(item.id.uuidString)-\($0)" })
    }

    // MARK: Tasks

    static func schedule(_ task: RemediationTask) {
        let id = taskID(task)
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard let due = task.dueDate, !task.isDone, !task.title.isEmpty else { return }
        requestPermissionIfNeeded()
        add(id: id, title: "Task Due Today", body: task.title, on: due)
    }

    static func cancel(_ task: RemediationTask) {
        center.removePendingNotificationRequests(withIdentifiers: [taskID(task)])
    }

    private static func taskID(_ task: RemediationTask) -> String {
        "task-\(task.reminderID.uuidString)"
    }

    // MARK: Shared

    private static func add(id: String, title: String, body: String, on date: Date) {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        guard let fireDate = Calendar.current.date(from: components), fireDate > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
