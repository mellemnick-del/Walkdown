import SwiftUI
import SwiftData

/// Every milestone: earned ones glow sunrise gold, the rest show quiet progress.
struct MilestonesView: View {
    @Query private var audits: [Audit]
    @Query private var tasks: [RemediationTask]
    @Query private var lockerItems: [LockerItem]
    @Query private var clients: [Client]

    private var stats: MilestoneStats {
        MilestoneStats(audits: audits, tasks: tasks, lockerItems: lockerItems, clients: clients,
                       walkAnswers: UserDefaults.standard.integer(forKey: Milestones.walkAnswersKey),
                       reportsOpened: UserDefaults.standard.integer(forKey: Milestones.reportsOpenedKey))
    }

    var body: some View {
        let stats = stats
        let earned = Milestones.earned(stats).count
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(earned) of \(Milestones.all.count) earned")
                        .font(.system(.title2, design: .serif).weight(.semibold))
                    Text("Earned through real work. Nothing expires, and there's no rush.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                    ForEach(Milestones.all) { milestone in
                        MilestoneTile(milestone: milestone, progress: Milestones.progress(milestone, stats))
                    }
                }
            }
            .padding()
        }
        .calmBackground()
        .navigationTitle("Milestones")
    }
}

struct MilestoneTile: View {
    let milestone: Milestone
    let progress: Int

    private var earned: Bool { progress >= milestone.goal }

    var body: some View {
        VStack(spacing: 10) {
            MilestoneMedal(symbol: milestone.symbol, earned: earned, size: 64)
            Text(milestone.title)
                .font(.system(.headline, design: .serif))
                .multilineTextAlignment(.center)
            Text(milestone.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if !earned && milestone.goal > 1 {
                ProgressView(value: Double(progress), total: Double(milestone.goal))
                    .tint(Theme.calmAmber)
                Text("\(progress) of \(milestone.goal)")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .top)
        .padding(14)
        .cardSurface(cornerRadius: 20)
        .opacity(earned ? 1 : 0.75)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(milestone.title), \(earned ? "earned" : "\(progress) of \(milestone.goal)"). \(milestone.detail)")
    }
}

/// A sunrise-gold medallion when earned, soft gray while locked.
struct MilestoneMedal: View {
    let symbol: String
    let earned: Bool
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .fill(earned ? AnyShapeStyle(Theme.dusk) : AnyShapeStyle(Color.secondary.opacity(0.15)))
            Circle()
                .strokeBorder(earned ? Theme.sunrise : Color.secondary.opacity(0.25), lineWidth: size * 0.05)
            Image(systemName: earned ? symbol : "lock.fill")
                .font(.system(size: size * (earned ? 0.4 : 0.32), weight: .semibold))
                .foregroundStyle(earned ? AnyShapeStyle(Theme.sun) : AnyShapeStyle(Color.secondary))
        }
        .frame(width: size, height: size)
        .shadow(color: earned ? Theme.sunrise.opacity(0.35) : .clear, radius: size * 0.15)
    }
}

/// The moment a milestone is earned: the medal rises in a drift of light.
struct MilestoneMoment: View {
    let milestone: Milestone
    let dismiss: () -> Void
    @State private var rise = false

    var body: some View {
        ZStack {
            Theme.dusk.opacity(0.94).ignoresSafeArea()
            LightMotes().ignoresSafeArea()
            VStack(spacing: 16) {
                Text("MILESTONE")
                    .font(.caption.bold())
                    .tracking(2)
                    .foregroundStyle(Theme.sunrise)
                MilestoneMedal(symbol: milestone.symbol, earned: true, size: 120)
                    .scaleEffect(rise ? 1 : 0.6)
                    .offset(y: rise ? 0 : 40)
                Text(milestone.title)
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                Text(milestone.detail)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .opacity(rise ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: dismiss)
        .onAppear {
            Haptics.drumroll()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { rise = true }
        }
        .task {
            try? await Task.sleep(for: .seconds(3.4))
            dismiss()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isModal)
    }
}
