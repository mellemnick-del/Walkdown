import Foundation
import SwiftData

/// Deleted audits wait in Recently Deleted for 30 days before they're removed for good, like Photos.
/// A deleted audit keeps everything (results, photos, findings, tasks); it's only hidden.
/// The deletion date and earlier status are kept in UserDefaults, so no database change is needed.
enum RecentlyDeleted {
    static let keepDays = 30
    private static let datesKey = "deletedAuditDates"
    private static let previousKey = "deletedAuditPreviousStatus"

    private static var dates: [String: Double] {
        get { UserDefaults.standard.dictionary(forKey: datesKey) as? [String: Double] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: datesKey) }
    }

    private static var previous: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: previousKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: previousKey) }
    }

    static func delete(_ audit: Audit, now: Date = .now) {
        let key = audit.id.uuidString
        dates[key] = now.timeIntervalSince1970
        previous[key] = audit.statusRaw
        audit.status = .deleted
        for task in audit.tasks ?? [] { ReminderScheduler.cancel(task) }
    }

    static func restore(_ audit: Audit) {
        let key = audit.id.uuidString
        audit.status = previous[key].flatMap(AuditStatus.init(rawValue:)) ?? .inProgress
        dates[key] = nil
        previous[key] = nil
        for task in audit.tasks ?? [] { ReminderScheduler.schedule(task) }
    }

    static func deletedAt(_ audit: Audit) -> Date? {
        dates[audit.id.uuidString].map(Date.init(timeIntervalSince1970:))
    }

    /// Whole days left before the audit is removed for good.
    static func daysLeft(_ audit: Audit, now: Date = .now) -> Int {
        guard let deleted = deletedAt(audit) else { return keepDays }
        let elapsed = Calendar.current.dateComponents([.day], from: deleted, to: now).day ?? 0
        return max(0, keepDays - elapsed)
    }

    static func deletePermanently(_ audit: Audit, in context: ModelContext) {
        let key = audit.id.uuidString
        for task in audit.tasks ?? [] { ReminderScheduler.cancel(task) }
        dates[key] = nil
        previous[key] = nil
        context.delete(audit)
    }

    /// Removes audits that have been in Recently Deleted for 30 days. Returns how many.
    @discardableResult
    static func purge(in context: ModelContext, now: Date = .now) -> Int {
        let deletedRaw = AuditStatus.deleted.rawValue
        let descriptor = FetchDescriptor<Audit>(predicate: #Predicate { $0.statusRaw == deletedRaw })
        guard let audits = try? context.fetch(descriptor) else { return 0 }
        var removed = 0
        for audit in audits {
            if deletedAt(audit) == nil {
                // No date on record (for example after a restore from backup): start the clock now.
                dates[audit.id.uuidString] = now.timeIntervalSince1970
            } else if daysLeft(audit, now: now) == 0 {
                deletePermanently(audit, in: context)
                removed += 1
            }
        }
        try? context.save()
        return removed
    }
}

extension Audit {
    /// True while the audit sits in Recently Deleted.
    var isInTrash: Bool { status == .deleted }
}
