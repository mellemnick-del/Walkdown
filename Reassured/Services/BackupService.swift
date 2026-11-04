import Foundation
import SwiftData

/// Exports audits, clients, and evidence to a single JSON backup file, and imports them back.
/// Importing adds what's missing and skips anything already on this device, so it's safe to
/// import the same backup twice.
enum BackupService {
    static let currentVersion = 1

    // MARK: File format

    struct BackupFile: Codable {
        var version: Int
        var exportedAt: Date
        var clients: [ClientRecord]
        var audits: [AuditRecord]
        var lockerItems: [LockerRecord]
    }

    struct ClientRecord: Codable {
        var id: UUID
        var name: String
        var industry: String
        var contactName: String
        var contactEmail: String
        var notes: String
        var createdAt: Date
    }

    struct AuditRecord: Codable {
        var id: UUID
        var clientID: UUID?
        var clientName: String
        var siteName: String
        var location: String
        var auditorName: String
        var date: Date
        var scopeNotes: String
        var checklistName: String
        var statusRaw: String
        var kindRaw: String
        var createdAt: Date
        var controls: [ControlRecord]
        var findings: [FindingRecord]
        var tasks: [TaskRecord]
    }

    struct ControlRecord: Codable {
        var controlID: String
        var title: String
        var guidance: String
        var groupName: String
        var groupOrder: Int
        var order: Int
        var statusRaw: String
        var notes: String
        var updatedAt: Date
        var evidence: [EvidenceRecord]
        var lockerItemIDs: [UUID]
    }

    struct EvidenceRecord: Codable {
        var imageData: Data
        var caption: String
        var createdAt: Date
    }

    struct FindingRecord: Codable {
        var title: String
        var detail: String
        var recommendation: String
        var severityRaw: String
        var createdAt: Date
        var controlID: String?
    }

    struct TaskRecord: Codable {
        var title: String
        var detail: String
        var owner: String
        var dueDate: Date?
        var priorityRaw: String
        var stateRaw: String
        var createdAt: Date
        var completedAt: Date?
        var controlID: String?
    }

    struct LockerRecord: Codable {
        var id: UUID
        var title: String
        var notes: String
        var kindRaw: String
        var topicsRaw: String
        var fileData: Data
        var fileName: String
        var contentTypeID: String
        var addedAt: Date
        var expiresAt: Date?
        var clientID: UUID?
    }

    struct ImportSummary: Equatable {
        var audits = 0
        var clients = 0
        var lockerItems = 0
        var skipped = 0

        var message: String {
            var parts: [String] = []
            if audits > 0 { parts.append("\(audits) audit\(audits == 1 ? "" : "s")") }
            if clients > 0 { parts.append("\(clients) client\(clients == 1 ? "" : "s")") }
            if lockerItems > 0 { parts.append("\(lockerItems) evidence item\(lockerItems == 1 ? "" : "s")") }
            var text = parts.isEmpty ? "Nothing new to import." : "Imported \(parts.joined(separator: ", "))."
            if skipped > 0 { text += " Skipped \(skipped) already on this device." }
            return text
        }
    }

    enum BackupError: LocalizedError {
        case newerVersion(Int)

        var errorDescription: String? {
            switch self {
            case .newerVersion(let version):
                "This backup was made by a newer version of Reassured (format \(version)). Update the app, then try again."
            }
        }
    }

    // MARK: Export

    /// Everything on the device.
    static func makeBackup(in context: ModelContext) throws -> BackupFile {
        let audits = try context.fetch(FetchDescriptor<Audit>()).filter { !$0.isInTrash }
        let clients = try context.fetch(FetchDescriptor<Client>())
        let locker = try context.fetch(FetchDescriptor<LockerItem>())
        return BackupFile(version: currentVersion, exportedAt: .now,
                          clients: clients.map(record), audits: audits.map(record), lockerItems: locker.map(record))
    }

    /// One audit, with its client and any linked evidence.
    static func makeBackup(of audit: Audit) -> BackupFile {
        var locker: [UUID: LockerItem] = [:]
        for control in audit.controls ?? [] {
            for item in control.lockerItems ?? [] { locker[item.id] = item }
        }
        return BackupFile(version: currentVersion, exportedAt: .now,
                          clients: audit.client.map { [record($0)] } ?? [],
                          audits: [record(audit)],
                          lockerItems: locker.values.map(record))
    }

    static func encode(_ backup: BackupFile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(backup)
    }

    /// Writes a backup to a temporary file for sharing.
    static func writeFile(_ backup: BackupFile, name: String) throws -> URL {
        let safe = name.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: "-")
        let stamp = Date.now.formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Reassured-\(safe)-\(stamp).json")
        try encode(backup).write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    // MARK: Import

    static func decode(_ data: Data) throws -> BackupFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupFile.self, from: data)
        guard backup.version <= currentVersion else { throw BackupError.newerVersion(backup.version) }
        return backup
    }

    @discardableResult
    static func importBackup(_ backup: BackupFile, into context: ModelContext) throws -> ImportSummary {
        var summary = ImportSummary()

        var clientsByID: [UUID: Client] = [:]
        for client in try context.fetch(FetchDescriptor<Client>()) { clientsByID[client.id] = client }
        for record in backup.clients {
            if clientsByID[record.id] != nil { summary.skipped += 1; continue }
            let client = Client(name: record.name, industry: record.industry)
            client.id = record.id
            client.contactName = record.contactName
            client.contactEmail = record.contactEmail
            client.notes = record.notes
            client.createdAt = record.createdAt
            context.insert(client)
            clientsByID[record.id] = client
            summary.clients += 1
        }

        var lockerByID: [UUID: LockerItem] = [:]
        for item in try context.fetch(FetchDescriptor<LockerItem>()) { lockerByID[item.id] = item }
        for record in backup.lockerItems {
            if lockerByID[record.id] != nil { summary.skipped += 1; continue }
            let item = LockerItem(title: record.title, fileData: record.fileData, fileName: record.fileName, contentType: .data)
            item.id = record.id
            item.notes = record.notes
            item.kindRaw = record.kindRaw
            item.topicsRaw = record.topicsRaw
            item.contentTypeID = record.contentTypeID
            item.addedAt = record.addedAt
            item.expiresAt = record.expiresAt
            context.insert(item)
            item.client = record.clientID.flatMap { clientsByID[$0] }
            lockerByID[record.id] = item
            ReminderScheduler.schedule(item)
            summary.lockerItems += 1
        }

        let existingAudits = Set(try context.fetch(FetchDescriptor<Audit>()).map(\.id))
        for record in backup.audits {
            if existingAudits.contains(record.id) { summary.skipped += 1; continue }
            let audit = Audit(clientName: record.clientName, siteName: record.siteName, location: record.location,
                              auditorName: record.auditorName, date: record.date, scopeNotes: record.scopeNotes,
                              checklistName: record.checklistName)
            audit.id = record.id
            audit.statusRaw = record.statusRaw
            audit.kindRaw = record.kindRaw
            audit.createdAt = record.createdAt
            context.insert(audit)
            audit.client = record.clientID.flatMap { clientsByID[$0] }

            var controlsByID: [String: ControlResult] = [:]
            for c in record.controls {
                let control = ControlResult(controlID: c.controlID, title: c.title, guidance: c.guidance,
                                            groupName: c.groupName, groupOrder: c.groupOrder, order: c.order)
                context.insert(control)
                control.audit = audit
                control.statusRaw = c.statusRaw
                control.notes = c.notes
                control.updatedAt = c.updatedAt
                for e in c.evidence {
                    let evidence = Evidence(imageData: e.imageData, caption: e.caption)
                    evidence.createdAt = e.createdAt
                    context.insert(evidence)
                    evidence.control = control
                }
                let linked = c.lockerItemIDs.compactMap { lockerByID[$0] }
                if !linked.isEmpty { control.lockerItems = linked }
                controlsByID[c.controlID] = control
            }
            for f in record.findings {
                let finding = Finding(title: f.title, detail: f.detail, recommendation: f.recommendation)
                finding.severityRaw = f.severityRaw
                finding.createdAt = f.createdAt
                context.insert(finding)
                finding.audit = audit
                finding.control = f.controlID.flatMap { controlsByID[$0] }
            }
            for t in record.tasks {
                let task = RemediationTask(title: t.title, detail: t.detail, owner: t.owner, dueDate: t.dueDate)
                task.priorityRaw = t.priorityRaw
                task.stateRaw = t.stateRaw
                task.createdAt = t.createdAt
                task.completedAt = t.completedAt
                context.insert(task)
                task.audit = audit
                task.control = t.controlID.flatMap { controlsByID[$0] }
                ReminderScheduler.schedule(task)
            }
            summary.audits += 1
        }
        try context.save()
        return summary
    }

    // MARK: Records

    private static func record(_ c: Client) -> ClientRecord {
        ClientRecord(id: c.id, name: c.name, industry: c.industry, contactName: c.contactName,
                     contactEmail: c.contactEmail, notes: c.notes, createdAt: c.createdAt)
    }

    private static func record(_ a: Audit) -> AuditRecord {
        AuditRecord(
            id: a.id, clientID: a.client?.id, clientName: a.clientName, siteName: a.siteName, location: a.location,
            auditorName: a.auditorName, date: a.date, scopeNotes: a.scopeNotes, checklistName: a.checklistName,
            statusRaw: a.statusRaw, kindRaw: a.kindRaw, createdAt: a.createdAt,
            controls: a.sortedControls.map { c in
                ControlRecord(controlID: c.controlID, title: c.title, guidance: c.guidance, groupName: c.groupName,
                              groupOrder: c.groupOrder, order: c.order, statusRaw: c.statusRaw, notes: c.notes,
                              updatedAt: c.updatedAt,
                              evidence: c.sortedEvidence.map { EvidenceRecord(imageData: $0.imageData, caption: $0.caption, createdAt: $0.createdAt) },
                              lockerItemIDs: (c.lockerItems ?? []).map(\.id))
            },
            findings: (a.findings ?? []).map { f in
                FindingRecord(title: f.title, detail: f.detail, recommendation: f.recommendation,
                              severityRaw: f.severityRaw, createdAt: f.createdAt, controlID: f.control?.controlID)
            },
            tasks: (a.tasks ?? []).map { t in
                TaskRecord(title: t.title, detail: t.detail, owner: t.owner, dueDate: t.dueDate,
                           priorityRaw: t.priorityRaw, stateRaw: t.stateRaw, createdAt: t.createdAt,
                           completedAt: t.completedAt, controlID: t.control?.controlID)
            }
        )
    }

    private static func record(_ l: LockerItem) -> LockerRecord {
        LockerRecord(id: l.id, title: l.title, notes: l.notes, kindRaw: l.kindRaw, topicsRaw: l.topicsRaw,
                     fileData: l.fileData, fileName: l.fileName, contentTypeID: l.contentTypeID,
                     addedAt: l.addedAt, expiresAt: l.expiresAt, clientID: l.client?.id)
    }
}
