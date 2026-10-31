import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Query private var audits: [Audit]
    @Query(filter: #Predicate<RemediationTask> { $0.stateRaw != "done" }) private var openTasks: [RemediationTask]
    @AppStorage(SettingsKeys.auditorName) private var name = ""

    @State private var showingNewAudit = false
    @State private var showingSettings = false
    @State private var showingHelp = false
    @State private var selectedTask: RemediationTask?

    private var activeAudits: [Audit] {
        audits.filter { $0.status == .inProgress }.sorted { $0.lastActivity > $1.lastActivity }
    }

    private var nextUp: [RemediationTask] {
        Array(openTasks.sorted(by: RemediationTask.nextUp).prefix(3))
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let part = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
        let first = name.split(separator: " ").first.map(String.init) ?? ""
        return first.isEmpty ? part : "\(part), \(first)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(greeting)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let focus = activeAudits.first {
                        FocusCard(audit: focus) { router.open(focus) }
                    } else {
                        WelcomeCard { showingNewAudit = true }
                    }

                    StatsRow(openTasks: openTasks, audits: activeAudits)

                    SectionTitle(title: "Next Up", actionLabel: openTasks.isEmpty ? nil : "See All") { router.tab = .tasks }
                    if nextUp.isEmpty {
                        Card {
                            Label("Nothing to fix right now. Failed controls become tasks when you build a remediation plan.",
                                  systemImage: "checkmark.seal")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Card {
                            VStack(spacing: 0) {
                                ForEach(Array(nextUp.enumerated()), id: \.element.id) { index, task in
                                    Button { selectedTask = task } label: { TaskRow(task: task, showsAudit: true) }
                                        .buttonStyle(.plain)
                                    if index < nextUp.count - 1 { Divider().padding(.vertical, 8) }
                                }
                            }
                        }
                    }

                    if activeAudits.count > 1 {
                        SectionTitle(title: "In Progress")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(activeAudits.dropFirst()) { audit in
                                    Button { router.open(audit) } label: { MiniAuditCard(audit: audit) }
                                        .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    SectionTitle(title: "Start Something")
                    HStack(spacing: 12) {
                        QuickAction(title: "New Audit", symbol: "plus.viewfinder") { showingNewAudit = true }
                        QuickAction(title: "Checklists", symbol: "books.vertical") { router.tab = .library }
                        QuickAction(title: "Get Help", symbol: "person.wave.2") { showingHelp = true }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Walkdown")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingSettings = true } label: { Label("Settings", systemImage: "gearshape") }
                }
            }
            .sheet(isPresented: $showingNewAudit) {
                NewAuditView { audit in router.open(audit) }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingHelp) { GetHelpView() }
            .sheet(item: $selectedTask) { task in
                NavigationStack { TaskDetailView(task: task) }
            }
        }
    }
}

private struct FocusCard: View {
    let audit: Audit
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            Card {
                HStack(spacing: 20) {
                    ScoreRing(score: audit.score, size: 110)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(audit.kind.label.uppercased())
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                        Text(audit.displayName)
                            .font(.title3.bold())
                            .lineLimit(2)
                        Text(audit.checklistName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        ProgressView(value: audit.progress)
                            .padding(.top, 4)
                        Text("\(audit.answeredCount) of \(audit.totalCount) controls done")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct WelcomeCard: View {
    let start: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                Text("Know where you stand")
                    .font(.title3.bold())
                Text("Run an on-site audit or a self-assessment against CMMC, HIPAA, PCI, SOC 2, NIST, and more. Walkdown scores it and turns every gap into a task.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Start Your First Assessment", action: start)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
        }
    }
}

private struct StatsRow: View {
    let openTasks: [RemediationTask]
    let audits: [Audit]

    var body: some View {
        let overdue = openTasks.filter(\.isOverdue).count
        let remaining = audits.reduce(0) { $0 + ($1.totalCount - $1.answeredCount) }
        HStack(spacing: 12) {
            Stat(value: openTasks.count, label: "Open Tasks", color: .accentColor)
            Stat(value: overdue, label: "Overdue", color: overdue > 0 ? .red : .secondary)
            Stat(value: remaining, label: "Controls Left", color: .secondary)
        }
    }

    private struct Stat: View {
        let value: Int
        let label: String
        let color: Color

        var body: some View {
            Card {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(value)")
                        .font(.title2.bold())
                        .monospacedDigit()
                        .foregroundStyle(color)
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }
}

private struct MiniAuditCard: View {
    let audit: Audit

    var body: some View {
        Card {
            HStack(spacing: 12) {
                ScoreRing(score: audit.score, size: 48, lineWidth: 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text(audit.displayName).font(.subheadline.bold()).lineLimit(1)
                    Text(audit.checklistName).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
        }
        .frame(width: 260)
    }
}

private struct QuickAction: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Card {
                VStack(spacing: 8) {
                    Image(systemName: symbol).font(.title2).foregroundStyle(.tint)
                    Text(title).font(.caption.bold()).lineLimit(1).minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }
}
