import SwiftUI
import SwiftData

@main
struct WalkdownApp: App {
    var body: some Scene {
        WindowGroup {
            LockGate {
                RootView()
            }
        }
        .modelContainer(for: [Audit.self, ControlResult.self, Evidence.self, Finding.self, RemediationTask.self, LockerItem.self, Client.self])
    }
}
