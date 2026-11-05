import WidgetKit
import SwiftUI

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        let snapshot: WidgetSnapshot = context.isPreview ? WidgetSnapshot.placeholder : (WidgetSnapshot.load() ?? WidgetSnapshot.empty)
        completion(SnapshotEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let entry = SnapshotEntry(date: .now, snapshot: WidgetSnapshot.load() ?? .empty)
        // The app asks for a refresh whenever something changes; this hourly refresh is a backstop.
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600))))
    }
}

@main
struct ReassuredWidgetBundle: WidgetBundle {
    var body: some Widget {
        WhereYouStandWidget()
    }
}

struct WhereYouStandWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WhereYouStand", provider: SnapshotProvider()) { entry in
            WidgetRootView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Where You Stand")
        .description("Your score and what to fix next.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Views

private enum Palette {
    static let navy = Color(red: 0.059, green: 0.173, blue: 0.361)
    static let teal = Color(red: 0.141, green: 0.373, blue: 0.498)
    static let ember = Color(red: 0.788, green: 0.541, blue: 0.294)
    static let sunrise = Color(red: 1.0, green: 0.851, blue: 0.541)
    static let green = Color(red: 0.37, green: 0.83, blue: 0.65)
    static let coral = Color(red: 0.94, green: 0.49, blue: 0.46)

    static let dusk = LinearGradient(stops: [
        .init(color: navy, location: 0), .init(color: teal, location: 0.75), .init(color: ember, location: 1),
    ], startPoint: .top, endPoint: .bottom)

    static func score(_ value: Double) -> Color {
        value >= 0.8 ? green : value >= 0.5 ? sunrise : coral
    }
}

struct WidgetRootView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            MediumView(snapshot: snapshot)
                .containerBackground(Palette.dusk, for: .widget)
        case .accessoryCircular:
            CircularView(snapshot: snapshot)
                .containerBackground(.clear, for: .widget)
        case .accessoryRectangular:
            RectangularView(snapshot: snapshot)
                .containerBackground(.clear, for: .widget)
        default:
            SmallView(snapshot: snapshot)
                .containerBackground(Palette.dusk, for: .widget)
        }
    }
}

private struct Ring: View {
    let score: Double?
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: score ?? 0)
                .stroke(Palette.score(score ?? 0), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(score.map { "\(Int(($0 * 100).rounded()))" } ?? "--")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .monospacedDigit()
                Text(score == nil ? "too early" : "score")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)
        }
    }
}

private struct SmallView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        if snapshot.auditName == nil {
            EmptyStateView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Ring(score: snapshot.score).frame(width: 66, height: 66)
                Spacer(minLength: 0)
                Text(snapshot.auditName ?? "")
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .privacySensitive()
                Text(snapshot.controlsLeft == 0 ? "All controls answered" : "\(snapshot.controlsLeft) controls left")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct MediumView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        if snapshot.auditName == nil && snapshot.nextTasks.isEmpty {
            EmptyStateView()
        } else {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Ring(score: snapshot.score).frame(width: 70, height: 70)
                    Text(snapshot.auditName ?? "")
                        .font(.system(.caption, design: .serif).weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .privacySensitive()
                }
                .frame(width: 92, alignment: .leading)
                VStack(alignment: .leading, spacing: 7) {
                    Text(snapshot.overdue > 0 ? "\(snapshot.overdue) overdue" : "Next up")
                        .font(.caption2.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(snapshot.overdue > 0 ? Palette.coral : Palette.sunrise)
                    if snapshot.nextTasks.isEmpty {
                        Text("Nothing to fix right now.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    ForEach(Array(snapshot.nextTasks.prefix(3).enumerated()), id: \.offset) { _, task in
                        HStack(alignment: .top, spacing: 6) {
                            Circle()
                                .fill(task.overdue ? Palette.coral : Palette.sunrise)
                                .frame(width: 6, height: 6)
                                .padding(.top, 5)
                            Text(task.title)
                                .font(.caption)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .privacySensitive()
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct CircularView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        Gauge(value: snapshot.score ?? 0) {
            Image(systemName: "sun.horizon.fill")
        } currentValueLabel: {
            Text(snapshot.score.map { "\(Int(($0 * 100).rounded()))" } ?? "--")
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}

private struct RectangularView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "sun.horizon.fill")
                Text(snapshot.score.map { "Score \(Int(($0 * 100).rounded()))%" } ?? "Reassured")
                    .font(.headline)
            }
            if let task = snapshot.nextTasks.first {
                Text(task.title)
                    .font(.caption)
                    .lineLimit(1)
                    .privacySensitive()
                Text(task.overdue ? "Overdue" : "\(snapshot.openTasks) open tasks")
                    .font(.caption2)
            } else {
                Text(snapshot.controlsLeft > 0 ? "\(snapshot.controlsLeft) controls left" : "All caught up")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "sun.horizon.fill")
                .font(.title2)
                .foregroundStyle(Palette.sunrise)
            Spacer(minLength: 0)
            Text("Know where you stand")
                .font(.system(.subheadline, design: .serif).weight(.semibold))
                .foregroundStyle(.white)
            Text("Start an audit in Reassured.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
