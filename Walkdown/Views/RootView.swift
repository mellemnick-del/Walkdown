import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()
    @AppStorage(Branding.colorKey) private var brandHex = Branding.defaultHex
    @AppStorage(SettingsKeys.hasOnboarded) private var hasOnboarded = false

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
        .tint(Color(uiColor: Branding.uiColor(hex: brandHex)))
        .fullScreenCover(isPresented: Binding(get: { !hasOnboarded }, set: { _ in })) {
            OnboardingView()
                .tint(Color(uiColor: Branding.uiColor(hex: brandHex)))
        }
    }
}
