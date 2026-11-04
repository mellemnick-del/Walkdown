import Foundation

/// Quiet recognition for real work. Milestones are worked out from the audits, tasks, and evidence
/// already in the app, so nothing new is stored except which ones have been celebrated.
struct Milestone: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let goal: Int
}

struct MilestoneStats: Equatable {
    var answeredControls = 0
    var completedAudits = 0
    var completedTasks = 0
    var lockerItems = 0
    var evidenceAllCurrent = false
    var clients = 0
    var bestScore: Double = 0
    var bestCompleteScore: Double = 0
    var areasCompleted = 0
    var cmmcCompleted = false
    var cleanSlate = false
    var walkAnswers = 0
    var reportsOpened = 0

    init() {}

    init(audits: [Audit], tasks: [RemediationTask], lockerItems: [LockerItem], clients: [Client],
         walkAnswers: Int, reportsOpened: Int) {
        answeredControls = audits.reduce(0) { $0 + $1.answeredCount }
        let completed = audits.filter { $0.status == .complete }
        completedAudits = completed.count
        completedTasks = tasks.filter(\.isDone).count
        self.lockerItems = lockerItems.count
        evidenceAllCurrent = lockerItems.count >= 5 && !lockerItems.contains(where: \.isExpired)
        self.clients = clients.count
        bestScore = audits.filter { $0.answeredCount >= 10 }.compactMap(\.score).max() ?? 0
        bestCompleteScore = completed.filter { $0.totalCount >= 15 }.compactMap(\.score).max() ?? 0
        areasCompleted = Set(completed.compactMap { audit in
            TemplateLibrary.all.first { $0.name == audit.checklistName }?.area
        }).count
        cmmcCompleted = completed.contains { $0.checklistName.hasPrefix("CMMC") }
        cleanSlate = audits.contains { audit in
            let tasks = audit.tasks ?? []
            return !tasks.isEmpty && tasks.allSatisfy(\.isDone)
        }
        self.walkAnswers = walkAnswers
        self.reportsOpened = reportsOpened
    }
}

enum Milestones {
    static let all: [Milestone] = [
        Milestone(id: "first-steps", title: "First Steps", detail: "Answer your first 10 controls.", symbol: "figure.walk", goal: 10),
        Milestone(id: "first-light", title: "First Light", detail: "Complete your first audit.", symbol: "sunrise.fill", goal: 1),
        Milestone(id: "steady-pace", title: "Steady Pace", detail: "Answer 25 controls in Walk Mode.", symbol: "shoeprints.fill", goal: 25),
        Milestone(id: "centurion", title: "Centurion", detail: "Answer 100 controls.", symbol: "checklist.checked", goal: 100),
        Milestone(id: "strong-score", title: "Strong Score", detail: "Reach 80% on an audit.", symbol: "gauge.with.dots.needle.67percent", goal: 1),
        Milestone(id: "gap-closer", title: "Gap Closer", detail: "Complete 10 remediation tasks.", symbol: "wrench.and.screwdriver.fill", goal: 10),
        Milestone(id: "clean-slate", title: "Clean Slate", detail: "Close every task from an audit.", symbol: "sparkles", goal: 1),
        Milestone(id: "report-ready", title: "Report Ready", detail: "Open a finished report.", symbol: "doc.richtext.fill", goal: 1),
        Milestone(id: "evidence-keeper", title: "Evidence Keeper", detail: "Keep 10 documents in the Locker.", symbol: "lock.doc.fill", goal: 10),
        Milestone(id: "always-current", title: "Always Current", detail: "Have 5 or more Locker documents, none expired.", symbol: "calendar.badge.checkmark", goal: 1),
        Milestone(id: "trusted-advisor", title: "Trusted Advisor", detail: "Add 3 clients.", symbol: "person.3.fill", goal: 3),
        Milestone(id: "well-rounded", title: "Well Rounded", detail: "Complete audits in 3 different areas.", symbol: "circle.hexagongrid.fill", goal: 3),
        Milestone(id: "defense-ready", title: "Defense Ready", detail: "Complete a CMMC audit.", symbol: "shield.lefthalf.filled", goal: 1),
        Milestone(id: "gold-standard", title: "Gold Standard", detail: "Finish an audit of 15+ controls at 95% or higher.", symbol: "rosette", goal: 1),
        Milestone(id: "thousand-checks", title: "Thousand Checks", detail: "Answer 1,000 controls.", symbol: "star.circle.fill", goal: 1000),
    ]

    /// Progress toward a milestone, capped at its goal.
    static func progress(_ milestone: Milestone, _ stats: MilestoneStats) -> Int {
        let value: Int = switch milestone.id {
        case "first-steps", "centurion", "thousand-checks": stats.answeredControls
        case "first-light": stats.completedAudits
        case "steady-pace": stats.walkAnswers
        case "strong-score": stats.bestScore >= 0.8 ? 1 : 0
        case "gap-closer": stats.completedTasks
        case "clean-slate": stats.cleanSlate ? 1 : 0
        case "report-ready": stats.reportsOpened
        case "evidence-keeper": stats.lockerItems
        case "always-current": stats.evidenceAllCurrent ? 1 : 0
        case "trusted-advisor": stats.clients
        case "well-rounded": stats.areasCompleted
        case "defense-ready": stats.cmmcCompleted ? 1 : 0
        case "gold-standard": stats.bestCompleteScore >= 0.95 ? 1 : 0
        default: 0
        }
        return min(value, milestone.goal)
    }

    static func earned(_ stats: MilestoneStats) -> [Milestone] {
        all.filter { progress($0, stats) >= $0.goal }
    }

    // MARK: Counters and celebrations, kept on this device

    private static let celebratedKey = "milestonesCelebrated"
    static let walkAnswersKey = "walkAnswerCount"
    static let reportsOpenedKey = "reportsOpenedCount"

    static func increment(_ key: String) {
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: key) + 1, forKey: key)
    }

    /// Milestones earned since the last check that haven't been celebrated yet.
    /// The very first check (for example right after an update) records what's already earned quietly.
    static func newlyEarned(_ stats: MilestoneStats, quietly: Bool = false) -> [Milestone] {
        let defaults = UserDefaults.standard
        let earnedIDs = Set(earned(stats).map(\.id))
        guard let stored = defaults.array(forKey: celebratedKey) as? [String], !quietly else {
            defaults.set(Array(earnedIDs), forKey: celebratedKey)
            return []
        }
        let celebrated = Set(stored)
        let fresh = all.filter { earnedIDs.contains($0.id) && !celebrated.contains($0.id) }
        if !fresh.isEmpty { defaults.set(Array(celebrated.union(earnedIDs)), forKey: celebratedKey) }
        return fresh
    }
}
