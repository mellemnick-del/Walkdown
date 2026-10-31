import SwiftUI
import SwiftData

@main
struct WalkdownApp: App {
    var body: some Scene {
        WindowGroup {
            LockGate {
                AuditListView()
            }
        }
        .modelContainer(for: [Audit.self, ControlResult.self, Evidence.self, Finding.self])
    }
}
