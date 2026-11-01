import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Back up everything to a file, or restore from one.
struct BackupView: View {
    @Environment(\.modelContext) private var context
    @State private var backupURL: URL?
    @State private var importing = false
    @State private var message: String?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                if let backupURL {
                    ShareLink(item: backupURL) {
                        Label("Save or Share Backup", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Button(action: makeBackup) {
                        Label("Create Backup", systemImage: "externaldrive.badge.plus")
                    }
                }
            } header: {
                Text("Back Up")
            } footer: {
                Text("One file with every audit, client, finding, task, photo, and Locker document. Save it to Files, iCloud Drive, or your Mac. It contains sensitive client data, so keep it somewhere private.")
            }

            Section {
                Button { importing = true } label: {
                    Label("Restore from Backup", systemImage: "square.and.arrow.down")
                }
            } footer: {
                Text("Adds anything that isn't already on this device and skips what is, so restoring the same backup twice is safe. Nothing is deleted.")
            }
        }
        .calmBackground()
        .navigationTitle("Backup")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                let backup = try BackupService.decode(try Data(contentsOf: url))
                message = try BackupService.importBackup(backup, into: context).message
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .alert("Restore Complete", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
        .alert("Couldn't Restore", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func makeBackup() {
        do {
            backupURL = try BackupService.writeFile(try BackupService.makeBackup(in: context), name: "Backup")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
