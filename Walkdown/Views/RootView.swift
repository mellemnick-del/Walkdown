import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()

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
            NavigationStack {
                ChecklistLibraryView()
            }
            .tabItem { Label("Library", systemImage: "books.vertical") }
            .tag(AppRouter.Tab.library)
        }
        .environment(router)
    }
}
