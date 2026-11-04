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
    @State private var demoWalk: Audit?
    @State private var demoReport: Audit?
    @State private var showingDemoGuide = false
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
        .fullScreenCover(item: $demoWalk) { WalkModeView(audit: $0) }
        .fullScreenCover(item: $demoReport) { audit in NavigationStack { ReportView(audit: audit) } }
        .fullScreenCover(isPresented: $showingDemoGuide) {
            NavigationStack { TemplatePreviewView(template: TemplateLibrary.cmmcLevel2) }
        }
        #endif
        .tint(Color(uiColor: Branding.uiColor(hex: brandHex)))
        .fullScreenCover(isPresented: Binding(get: { !hasOnboarded }, set: { _ in })) {
            OnboardingView()
                .tint(Color(uiColor: Branding.uiColor(hex: brandHex)))
        }
        .environment(router)
        .environment(lockerLock)
    }

    #if DEBUG
    private var demoAudit: Audit? {
        allAudits.first { $0.checklistName.hasPrefix("CMMC Level 2") }
    }

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
            if let audit = demoAudit { router.open(audit) }
        case "walk": demoWalk = demoAudit
        case "report": demoReport = demoAudit
        case "guide": showingDemoGuide = true
        case "pdf":
            // Writes the report for review; the screenshot workflow copies it off the simulator.
            if let audit = demoAudit {
                let data = ReportBuilder.makePDFData(for: audit, companyName: "Northline Advisory",
                                                     summary: AuditWriter.savedSummary(for: audit))
                try? data.write(to: URL.documentsDirectory.appendingPathComponent("report.pdf"))
            }
        default: router.tab = .home
        }
    }
    #endif
}
