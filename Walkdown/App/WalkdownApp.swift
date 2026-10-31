import SwiftUI
import SwiftData

@main
struct WalkdownApp: App {
    private let container: ModelContainer

    init() {
        let schema = Schema([Audit.self, ControlResult.self, Evidence.self, Finding.self,
                             RemediationTask.self, LockerItem.self, Client.self])
        #if DEBUG
        let demo = DemoData.isEnabled
        #else
        let demo = false
        #endif
        // Demo data lives in memory only and never touches real audits.
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: demo)
        do {
            container = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Couldn't open the Walkdown database: \(error)")
        }
        #if DEBUG
        if demo { DemoData.seed(container.mainContext) }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            LockGate {
                RootView()
            }
        }
        .modelContainer(container)
    }
}
