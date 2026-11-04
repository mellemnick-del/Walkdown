import SwiftUI

/// App-wide navigation so Home can open the Audits tab on a specific audit.
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case home, audits, tasks, locker, library
    }

    var tab: Tab = .home
    var auditToOpen: Audit?
    /// Set when an audit should open showing only its unanswered controls.
    var openToUnanswered = false
    /// Bumped to make the Tasks tab show open tasks.
    var showOpenTasks = 0

    func open(_ audit: Audit, unansweredOnly: Bool = false) {
        openToUnanswered = unansweredOnly
        tab = .audits
        auditToOpen = audit
    }

    func openTasks() {
        tab = .tasks
        showOpenTasks += 1
    }
}
