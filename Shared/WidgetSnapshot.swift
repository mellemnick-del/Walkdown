import Foundation

/// A small summary the app writes for the Home Screen and Lock Screen widgets.
/// Shared through an App Group, because widgets can't open the app's database.
struct WidgetSnapshot: Codable, Equatable {
    struct TaskLine: Codable, Equatable {
        var title: String
        var priority: String
        var due: Date?
        var overdue: Bool
    }

    var auditName: String?
    var checklist: String?
    var score: Double?
    var answered: Int
    var total: Int
    var openTasks: Int
    var overdue: Int
    var nextTasks: [TaskLine]
    var updatedAt: Date

    static let appGroup = "group.com.nickmellem.reassured"

    private static var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent("widget.json")
    }

    static func load() -> WidgetSnapshot? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    /// Saved readable after the first unlock, so widgets can refresh later while the phone is locked.
    /// Client names and task titles are hidden on the Lock Screen by the widget itself.
    func save() {
        guard let url = Self.fileURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self) else { return }
        try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    var controlsLeft: Int { max(0, total - answered) }

    static let empty = WidgetSnapshot(auditName: nil, checklist: nil, score: nil, answered: 0, total: 0,
                                      openTasks: 0, overdue: 0, nextTasks: [], updatedAt: .now)

    static let placeholder = WidgetSnapshot(
        auditName: "Lone Star Machining", checklist: "CMMC Level 2", score: 0.77, answered: 79, total: 110,
        openTasks: 22, overdue: 1,
        nextTasks: [
            TaskLine(title: "Fix: Multifactor authentication", priority: "Critical", due: .now, overdue: true),
            TaskLine(title: "Fix: Control the flow of CUI", priority: "High", due: .now, overdue: false),
            TaskLine(title: "Fix: Trace actions to users", priority: "High", due: .now, overdue: false),
        ],
        updatedAt: .now)
}
