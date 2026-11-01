import SwiftUI
import SwiftData

@main
struct ReassuredApp: App {
    private let container: ModelContainer

    init() {
        Theme.applyNavigationStyle()
        #if DEBUG
        let demo = DemoData.isEnabled
        #else
        let demo = false
        #endif
        // Demo data lives in memory only and never touches real audits.
        do {
            container = try ReassuredStore.makeContainer(inMemory: demo)
        } catch {
            fatalError("Couldn't open the Reassured database: \(error)")
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
