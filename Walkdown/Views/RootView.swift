import SwiftUI
import SwiftData

struct RootView: View {
    @State private var router = AppRouter()
    @AppStorage(Branding.colorKey) private var brandHex = Branding.defaultHex
    @AppStorage(SettingsKeys.hasOnboarded) private var hasOnboarded = false
    #if DEBUG
    @Query private var allAudits: [Audit]
    #endif

    var body: some View {
        TabView(selection: $router.tab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "gauge.with.dots.needle.67percent") }
                .tag(AppRouter.Tab.home)
            AuditListView()
                .tabItem { Label("Audits", systemImage: "checklist") }
                .tag(AppRouter.Tab.audits)
            TasksView()
                .tabItem { Label("Tasks", systemImage: "wrench.and.screwdriver") }
                .tag(AppRouter.Tab.tasks)
            LockerView()
                .tabItem { Label("Locker", systemImage: "lock.doc") }
                .tag(AppRouter.Tab.locker)
            NavigationStack {
                ChecklistLibraryView()
            }
            .tabItem { Label("Library", systemImage: "books.vertical") }
            .tag(AppRouter.Tab.library)
        }
        .environment(router)
        #if DEBUG
        .onAppear(perform: openDemoScreen)
        #endif
        .tint(Color(uiColor: Branding.uiColor(hex: brandHex)))
        .fullScreenCover(isPresented: Binding(get: { !hasOnboarded }, set: { _ in })) {
            OnboardingView()
                .tint(Color(uiColor: Branding.uiColor(hex: brandHex)))
        }
    }

    #if DEBUG
    /// Jumps to a screen for demo screenshots (see DemoData).
    private func openDemoScreen() {
        guard DemoData.isEnabled, let screen = DemoData.screen else { return }
        switch screen {
        case "audits": router.tab = .audits
        case "tasks": router.tab = .tasks
        case "locker": router.tab = .locker
        case "library": router.tab = .library
        case "workspace":
            if let audit = allAudits.first(where: { $0.checklistName.hasPrefix("CMMC Level 2") }) { router.open(audit) }
        default: router.tab = .home
        }
    }
    #endif
}
