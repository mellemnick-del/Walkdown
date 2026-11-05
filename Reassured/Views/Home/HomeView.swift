import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Query private var storedAudits: [Audit]
    @Query(filter: #Predicate<RemediationTask> { $0.stateRaw != "done" }) private var storedOpenTasks: [RemediationTask]
    @Query private var lockerItems: [LockerItem]
    @Query private var storedTasks: [RemediationTask]
    @Query private var clients: [Client]
    @AppStorage(SettingsKeys.auditorName) private var name = ""
    @AppStorage(SettingsKeys.userRole) private var roleRaw = UserRole.organization.rawValue

    private var role: UserRole { UserRole(rawValue: roleRaw) ?? .organization }
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var showingNewAudit = false
    @State private var showingSettings = false
    @State private var showingHelp = false
    @State private var selectedTask: RemediationTask?

    private var activeAudits: [Audit] {
        audits.filter { $0.status == .inProgress }.sorted { $0.lastActivity > $1.lastActivity }
    }

    private var audits: [Audit] { storedAudits.filter { !$0.isInTrash } }
    private var openTasks: [RemediationTask] { storedOpenTasks.filter { !($0.audit?.isInTrash ?? false) } }
    private var allTasks: [RemediationTask] { storedTasks.filter { !($0.audit?.isInTrash ?? false) } }

    private var nextUp: [RemediationTask] {
        Array(openTasks.sorted(by: RemediationTask.nextUp).prefix(3))
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let part = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
        let first = name.split(separator: " ").first.map(String.init) ?? ""
        return first.isEmpty ? part : "\(part), \(first)"
    }

    private var greetingSymbol: String {
        let hour = Calendar.current.component(.hour, from: .now)
        return hour < 12 ? "sunrise.fill" : hour < 17 ? "sun.max.fill" : "moon.stars.fill"
    }

    private var subtitle: String {
        let overdue = openTasks.filter(\.isOverdue).count
        if activeAudits.isEmpty && openTasks.isEmpty { return "Let's see where you stand." }
        if overdue > 0 { return "A few things need you today. You've got this." }
        if let focus = activeAudits.first, focus.answeredCount < focus.totalCount {
            let left = focus.totalCount - focus.answeredCount
            let controls = left == 1 ? "1 control" : "\(left) controls"
            if focus.answeredCount < Audit.minimumScoredAnswers { return "Good start. \(controls) to go." }
            if focus.progress < 0.75 { return "Making progress. \(controls) to go." }
            return "Almost there. \(controls) to go."
        }
        if openTasks.isEmpty { return "Everything's on track. Nice work." }
        return "Here's where you stand today."
    }

    @ViewBuilder
    private var headerSection: some View {
                    // Title and Settings share one row, right under the status bar.
                    HStack(alignment: .center) {
                        Text("Reassured")
                            .font(.system(size: 42, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.brandGradient)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Button { showingSettings = true } label: {
                            Image(systemName: "gearshape")
                                .font(.title3.weight(.medium))
                                .frame(width: 44, height: 44)
                                .cardSurface(cornerRadius: 22)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .accessibilityLabel("Settings")
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Label(greeting, systemImage: greetingSymbol)
                            .font(.headline)
                            .foregroundStyle(Theme.adaptive(light: UIColor(red: 0.059, green: 0.173, blue: 0.361, alpha: 1), dark: .white))
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
    }

    @ViewBuilder
    private var focusSection: some View {
                    if let focus = activeAudits.first {
                        FocusCard(audit: focus) { router.open(focus) }
                    } else {
                        WelcomeCard(role: role) { showingNewAudit = true }
                    }
    }

    @ViewBuilder
    private var statsSection: some View {
                    StatsRow(openTasks: openTasks, audits: activeAudits,
                             showTasks: { router.openTasks() },
                             showUnanswered: {
                                 if let focus = activeAudits.first(where: { $0.answeredCount < $0.totalCount }) ?? activeAudits.first {
                                     router.open(focus, unansweredOnly: true)
                                 } else {
                                     router.tab = .audits
                                 }
                             })
    }

    @ViewBuilder
    private var attentionSection: some View {
                    let needsAttention = lockerItems.filter { $0.isExpired || $0.isExpiringSoon }
                    if !needsAttention.isEmpty {
                        Button { router.tab = .locker } label: {
                            Card {
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.title2)
                                        .foregroundStyle(Theme.calmAmber)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(needsAttention.count) evidence item\(needsAttention.count == 1 ? "" : "s") need attention")
                                            .font(.subheadline.bold())
                                        Text("Expired or expiring within 30 days")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
    }

    @ViewBuilder
    private var nextUpSection: some View {
                    SectionTitle(title: "Next Up", actionLabel: openTasks.isEmpty ? nil : "See All") { router.tab = .tasks }
                    if nextUp.isEmpty {
                        Card {
                            Label(allTasks.isEmpty
                                  ? "Nothing to fix yet. Failed controls become tasks when you build a remediation plan."
                                  : "Every gap is closed. Enjoy it.",
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
    }

    @ViewBuilder
    private var inProgressSection: some View {
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
    }

    @ViewBuilder
    private var milestonesSection: some View {
                    MilestonesCard(stats: MilestoneStats(
                        audits: audits, tasks: allTasks, lockerItems: lockerItems, clients: clients,
                        walkAnswers: UserDefaults.standard.integer(forKey: Milestones.walkAnswersKey),
                        reportsOpened: UserDefaults.standard.integer(forKey: Milestones.reportsOpenedKey)))
    }

    @ViewBuilder
    private var startSection: some View {
                    SectionTitle(title: "Start Something")
                    HStack(spacing: 12) {
                        QuickAction(title: role == .organization ? "Self-Assess" : "New Audit",
                                    symbol: "plus.viewfinder") { showingNewAudit = true }
                        QuickAction(title: "Checklists", symbol: "books.vertical") { router.tab = .library }
                        QuickAction(title: "Get Help", symbol: "person.wave.2") { showingHelp = true }
                    }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    if sizeClass == .regular {
                        // iPad: status on the left, what to do next on the right.
                        HStack(alignment: .top, spacing: 20) {
                            VStack(alignment: .leading, spacing: 16) {
                                focusSection
                                statsSection
                                attentionSection
                                milestonesSection
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                            VStack(alignment: .leading, spacing: 16) {
                                nextUpSection
                                inProgressSection
                                startSection
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                        }
                    } else {
                        focusSection
                        statsSection
                        attentionSection
                        nextUpSection
                        inProgressSection
                        milestonesSection
                        startSection
                    }
                }
                .padding()
                .frame(maxWidth: 1200)
                .frame(maxWidth: .infinity)
            }
            .scrollContentBackground(.hidden)
            .background(SkyBackground())
            .navigationTitle("Home")
            .toolbar(.hidden, for: .navigationBar)
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
            HStack(spacing: 20) {
                ScoreRing(score: audit.score, size: 112, onDark: true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(audit.kind.label.uppercased())
                        .font(.caption2.bold())
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(audit.displayName)
                        .font(.system(.title3, design: .serif).weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(audit.checklistName)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                    ProgressView(value: audit.progress)
                        .tint(Theme.sunrise)
                        .padding(.top, 4)
                    Text("\(audit.answeredCount) of \(audit.totalCount) controls done")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.dusk, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Theme.navy.opacity(0.25), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

private struct WelcomeCard: View {
    let role: UserRole
    let start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ReassuredMark(size: 64)
            Text(role == .organization ? "Know where you stand" : "Your next audit starts here")
                .font(.system(.title2, design: .serif).weight(.semibold))
                .foregroundStyle(.white)
            Text(role == .organization
                 ? "Self-assess against CMMC, HIPAA, PCI, SOC 2, NIST, and more. Reassured scores it and turns every gap into a task."
                 : "Pick a checklist, walk the site, capture evidence, and hand your client a clean report with a remediation plan.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            Button(action: start) {
                Text(role == .organization ? "Start Your First Self-Assessment" : "Start Your First Audit")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.sunrise, in: Capsule())
                    .foregroundStyle(Theme.deepNavy)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.dusk, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct StatsRow: View {
    let openTasks: [RemediationTask]
    let audits: [Audit]
    let showTasks: () -> Void
    let showUnanswered: () -> Void

    var body: some View {
        let overdue = openTasks.filter(\.isOverdue).count
        let remaining = audits.reduce(0) { $0 + ($1.totalCount - $1.answeredCount) }
        HStack(spacing: 12) {
            Stat(value: openTasks.count, label: "Open Tasks", symbol: "wrench.and.screwdriver.fill",
                 color: Theme.calmBlue, action: showTasks)
            Stat(value: overdue, label: "Overdue", symbol: "clock.badge.exclamationmark.fill",
                 color: overdue > 0 ? Theme.calmCoral : Theme.calmGreen, action: showTasks)
            Stat(value: remaining, label: "Controls Left", symbol: "checklist",
                 color: Theme.calmAmber, action: showUnanswered)
        }
    }

    private struct Stat: View {
        let value: Int
        let label: String
        let symbol: String
        let color: Color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Card {
                    VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Image(systemName: symbol)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(color)
                            .frame(width: 32, height: 32)
                            .background(color.opacity(0.16), in: Circle())
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    Text("\(value)")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    }
                }
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("\(value) \(label)")
            .accessibilityHint(label == "Controls Left" ? "Opens your current audit's unanswered controls" : "Opens Tasks")
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
                VStack(spacing: 10) {
                    Image(systemName: symbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.sunrise)
                        .frame(width: 48, height: 48)
                        .background(Theme.dusk, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Text(title).font(.subheadline.bold()).lineLimit(1).minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// A small Home card: milestones earned and the closest one to go.
private struct MilestonesCard: View {
    let stats: MilestoneStats

    var body: some View {
        let earned = Milestones.earned(stats)
        let next = Milestones.all
            .filter { Milestones.progress($0, stats) < $0.goal }
            .max { fraction($0) < fraction($1) }
        NavigationLink {
            MilestonesView()
        } label: {
            Card {
                HStack(spacing: 14) {
                    MilestoneMedal(symbol: earned.last?.symbol ?? "sunrise.fill", earned: !earned.isEmpty, size: 48)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(earned.count) of \(Milestones.all.count) milestones")
                            .font(.system(.headline, design: .serif))
                        if let next {
                            Text("Next: \(next.title). \(next.detail)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            if next.goal > 1 {
                                ProgressView(value: fraction(next)).tint(Theme.calmAmber)
                            }
                        } else {
                            Text("Every milestone earned. Remarkable work.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func fraction(_ milestone: Milestone) -> Double {
        Double(Milestones.progress(milestone, stats)) / Double(milestone.goal)
    }
}
