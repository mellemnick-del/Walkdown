import SwiftUI
import SwiftData

struct RootView: View {
    @State private var router = AppRouter()
    @AppStorage(Branding.colorKey) private var brandHex = Branding.defaultHex
    @AppStorage(SettingsKeys.hasOnboarded) private var hasOnboarded = false
    @State private var showingOpening = true
    @State private var lockerLock = LockerLock()
    @Environment(\.scenePhase) private var scenePhase
    #if DEBUG
    @Query private var allAudits: [Audit]
    @State private var showingFontPreview = false
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
        .environment(lockerLock)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { lockerLock.lock() }
        }
        .overlay {
            if showingOpening && hasOnboarded {
                OpeningView { withAnimation(.easeOut(duration: 0.45)) { showingOpening = false } }
                    .transition(.opacity)
            }
        }
        #if DEBUG
        .onAppear(perform: openDemoScreen)
        .fullScreenCover(isPresented: $showingFontPreview) { FontPreviewView() }
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
        guard DemoData.isEnabled else { return }
        showingOpening = false
        guard let screen = DemoData.screen else { return }
        switch screen {
        case "fonts": showingFontPreview = true
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
