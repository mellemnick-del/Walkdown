import SwiftUI

/// App-wide navigation so Home can open the Audits tab on a specific audit.
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case home, audits, tasks, locker, library
    }

    var tab: Tab = .home
    var auditToOpen: Audit?

    func open(_ audit: Audit) {
        tab = .audits
        auditToOpen = audit
    }
}
