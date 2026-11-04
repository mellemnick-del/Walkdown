import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var context
    @Query private var storedTasks: [RemediationTask]

    private var tasks: [RemediationTask] { storedTasks.filter { !($0.audit?.isInTrash ?? false) } }
    @State private var showDone = false
    @State private var newTask: RemediationTask?

    private struct TaskSection: Identifiable {
        let title: String
        let tasks: [RemediationTask]
        var id: String { title }
    }

    private var sections: [TaskSection] {
        if showDone {
            let done = tasks.filter(\.isDone).sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            return done.isEmpty ? [] : [TaskSection(title: "Completed", tasks: done)]
        }
        let open = tasks.filter { !$0.isDone }.sorted(by: RemediationTask.nextUp)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekOut = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        let buckets: [(String, (RemediationTask) -> Bool)] = [
            ("Overdue", { $0.isOverdue }),
            ("Due This Week", { !$0.isOverdue && ($0.dueDate.map { $0 < weekOut } ?? false) }),
            ("Later", { ($0.dueDate.map { $0 >= weekOut } ?? false) }),
            ("No Due Date", { $0.dueDate == nil }),
        ]
        return buckets.compactMap { title, test in
            let matching = open.filter(test)
            return matching.isEmpty ? nil : TaskSection(title: title, tasks: matching)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Picker("Show", selection: $showDone) {
                    Text("Open").tag(false)
                    Text("Done").tag(true)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                if sections.isEmpty {
                    ContentUnavailableView {
                        Label(showDone ? "Nothing Finished Yet" : "Nothing to Fix", systemImage: showDone ? "checkmark.seal" : "sun.horizon")
                    } description: {
                        Text(showDone
                             ? "Finished fixes land here. The first one always feels good."
                             : tasks.isEmpty
                                ? "Open an audit and choose Build Remediation Plan to turn failed controls into tasks."
                                : "Every gap is closed. Enjoy it.")
                    }
                    .listRowBackground(Color.clear)
                }

                ForEach(sections) { section in
                    Section(section.title) {
                        ForEach(section.tasks) { task in
                            NavigationLink {
                                TaskDetailView(task: task)
                            } label: {
                                TaskRow(task: task, showsAudit: true)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        task.state = task.isDone ? .open : .done
                                    }
                                    ReminderScheduler.schedule(task)
                                } label: {
                                    Label(task.isDone ? "Reopen" : "Done",
                                          systemImage: task.isDone ? "arrow.uturn.backward" : "checkmark")
                                }
                                .tint(task.isDone ? Theme.calmAmber : Theme.calmGreen)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    ReminderScheduler.cancel(task)
                                    context.delete(task)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .calmBackground()
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addTask) { Label("New Task", systemImage: "plus") }
                }
            }
            .sheet(item: $newTask) { task in
                NavigationStack { TaskDetailView(task: task, isNew: true) }
            }
        }
    }

    private func addTask() {
        let task = RemediationTask(title: "")
        context.insert(task)
        newTask = task
    }
}

/// Compact task row used on Home, the Tasks tab, and controls.
struct TaskRow: View {
    let task: RemediationTask
    var showsAudit = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(task.isDone ? Theme.calmGreen : task.priority.color)
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title.isEmpty ? "Untitled task" : task.title)
                    .font(.body)
                    .strikethrough(task.isDone)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(task.priority.label).foregroundStyle(task.priority.color)
                    if let due = task.dueDate {
                        Text(task.isOverdue ? "Overdue \(due.formatted(.dateTime.month().day()))"
                                            : "Due \(due.formatted(.dateTime.month().day()))")
                            .foregroundStyle(task.isOverdue ? Theme.calmCoral : .secondary)
                    }
                    if !task.owner.isEmpty {
                        Label(task.owner, systemImage: "person").labelStyle(.titleAndIcon)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if showsAudit, let audit = task.audit {
                    Text(audit.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}
