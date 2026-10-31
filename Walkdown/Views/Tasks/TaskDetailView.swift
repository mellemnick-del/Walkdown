import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Bindable var task: RemediationTask
    var isNew = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var askToPassControl = false
    @State private var confirmingDelete = false

    private var hasDueDate: Binding<Bool> {
        Binding(
            get: { task.dueDate != nil },
            set: { on in
                task.dueDate = on
                    ? Calendar.current.date(byAdding: .day, value: task.priority.suggestedDays, to: .now)
                    : nil
            }
        )
    }

    private var dueDate: Binding<Date> {
        Binding(get: { task.dueDate ?? .now }, set: { task.dueDate = $0 })
    }

    var body: some View {
        Form {
            Section {
                TextField("What needs to be fixed?", text: $task.title, axis: .vertical)
                    .font(.headline)
                Picker("Priority", selection: $task.priority) {
                    ForEach(Severity.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section("Status") {
                Picker("Status", selection: $task.state) {
                    ForEach(TaskState.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: task.state) { _, newState in
                    if newState == .done, let control = task.control, control.status != .pass {
                        askToPassControl = true
                    }
                }
            }

            Section("Assignment") {
                TextField("Owner", text: $task.owner)
                Toggle("Due date", isOn: hasDueDate)
                if task.dueDate != nil {
                    DatePicker("Due", selection: dueDate, displayedComponents: .date)
                }
            }

            Section("How to fix it") {
                TextField("Steps, notes, links", text: $task.detail, axis: .vertical)
                    .lineLimit(4...16)
            }

            if let control = task.control {
                Section("Control") {
                    NavigationLink {
                        ControlDetailView(control: control)
                    } label: {
                        HStack(spacing: 10) {
                            StatusIcon(status: control.status)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(control.controlID).font(.caption.monospaced()).foregroundStyle(.secondary)
                                Text(control.title).font(.subheadline)
                            }
                        }
                    }
                    if let audit = task.audit {
                        LabeledContent("Audit", value: audit.displayName)
                    }
                }
            }

            if !isNew {
                Section {
                    Button("Delete Task", role: .destructive) { confirmingDelete = true }
                }
            }
        }
        .navigationTitle(isNew ? "New Task" : "Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        context.delete(task)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                        .disabled(task.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .interactiveDismissDisabled(isNew)
        .confirmationDialog("Mark the control as passing too?", isPresented: $askToPassControl, titleVisibility: .visible) {
            Button("Mark \(task.control?.controlID ?? "Control") as Pass") { task.control?.status = .pass }
            Button("Leave It As Is", role: .cancel) {}
        } message: {
            Text("Closing a task doesn't change the audit result on its own. Update the control if the fix is verified.")
        }
        .confirmationDialog("Delete this task?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(task)
                dismiss()
            }
        }
    }
}
