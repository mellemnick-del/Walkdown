import Foundation
import SwiftData
import UniformTypeIdentifiers

enum EvidenceKind: String, Codable, CaseIterable, Identifiable {
    case policy, procedure, report, screenshot, certificate, contract, training, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .policy: "Policy"
        case .procedure: "Procedure"
        case .report: "Report"
        case .screenshot: "Screenshot"
        case .certificate: "Certificate"
        case .contract: "Contract"
        case .training: "Training Record"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .policy: "doc.text"
        case .procedure: "list.number"
        case .report: "chart.bar.doc.horizontal"
        case .screenshot: "photo"
        case .certificate: "rosette"
        case .contract: "signature"
        case .training: "graduationcap"
        case .other: "doc"
        }
    }
}

/// Common security topics. Evidence is tagged with topics so it can be suggested for matching
/// controls in any framework, which is how one document gets reused across CMMC, SOC 2, HIPAA, and others.
enum EvidenceTopic: String, Codable, CaseIterable, Identifiable {
    case accessControl, mfa, encryption, backups, incidentResponse, training, logging, vulnerability,
         patching, assetInventory, configuration, physical, vendors, continuity, policies, personnel, privacy

    var id: String { rawValue }

    var label: String {
        switch self {
        case .accessControl: "Access Control"
        case .mfa: "MFA"
        case .encryption: "Encryption"
        case .backups: "Backups"
        case .incidentResponse: "Incident Response"
        case .training: "Training"
        case .logging: "Logging and Monitoring"
        case .vulnerability: "Vulnerability and Pen Testing"
        case .patching: "Patching"
        case .assetInventory: "Asset Inventory"
        case .configuration: "Configuration and Change"
        case .physical: "Physical Security"
        case .vendors: "Vendors"
        case .continuity: "Business Continuity"
        case .policies: "Policies and Governance"
        case .personnel: "Personnel"
        case .privacy: "Privacy"
        }
    }

    /// Words that suggest a control relates to this topic.
    var keywords: [String] {
        switch self {
        case .accessControl: ["access", "privilege", "account", "authoriz"]
        case .mfa: ["multifactor", "mfa", "authenticat"]
        case .encryption: ["encrypt", "cryptograph", "fips", "tls"]
        case .backups: ["backup", "restore"]
        case .incidentResponse: ["incident", "breach"]
        case .training: ["training", "awareness"]
        case .logging: ["log", "audit record", "monitor"]
        case .vulnerability: ["vulnerab", "scan", "penetration"]
        case .patching: ["patch", "flaw", "update"]
        case .assetInventory: ["inventory", "asset"]
        case .configuration: ["configuration", "change", "baseline", "harden"]
        case .physical: ["physical", "facility", "visitor", "badge"]
        case .vendors: ["vendor", "supplier", "supply chain", "service provider", "business associate", "processor"]
        case .continuity: ["continuity", "contingency", "disaster", "recovery"]
        case .policies: ["policy", "policies", "governance", "plan", "oversight"]
        case .personnel: ["personnel", "screen", "background", "termination", "hire"]
        case .privacy: ["privacy", "personal data", "pii", "consent", "data subject"]
        }
    }

    static func suggested(for control: ControlResult) -> Set<EvidenceTopic> {
        let text = "\(control.title) \(control.guidance)".lowercased()
        return Set(allCases.filter { topic in topic.keywords.contains { text.contains($0) } })
    }
}

/// A document or image kept in the Evidence Locker, linkable to controls in any audit.
@Model
final class LockerItem {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var kindRaw: String = EvidenceKind.other.rawValue
    var topicsRaw: String = ""
    @Attribute(.externalStorage)
    var fileData: Data = Data()
    var fileName: String = ""
    var contentTypeID: String = UTType.data.identifier
    var addedAt: Date = Date.now
    var expiresAt: Date?

    @Relationship(deleteRule: .nullify, inverse: \ControlResult.lockerItems)
    var controls: [ControlResult]? = []

    init(title: String, fileData: Data, fileName: String, contentType: UTType, kind: EvidenceKind = .other) {
        self.title = title
        self.fileData = fileData
        self.fileName = fileName
        self.contentTypeID = contentType.identifier
        self.kindRaw = kind.rawValue
    }

    var kind: EvidenceKind {
        get { EvidenceKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    var topics: Set<EvidenceTopic> {
        get { Set(topicsRaw.split(separator: ",").compactMap { EvidenceTopic(rawValue: String($0)) }) }
        set { topicsRaw = newValue.map(\.rawValue).sorted().joined(separator: ",") }
    }

    var contentType: UTType { UTType(contentTypeID) ?? .data }

    var isImage: Bool { contentType.conforms(to: .image) }

    var daysUntilExpiry: Int? {
        guard let expiresAt else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: .now),
                                       to: calendar.startOfDay(for: expiresAt)).day
    }

    var isExpired: Bool { (daysUntilExpiry ?? 1) < 0 }

    /// Expires within 30 days but hasn't yet.
    var isExpiringSoon: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days >= 0 && days <= 30
    }

    var expiryText: String? {
        guard let days = daysUntilExpiry, let expiresAt else { return nil }
        if days < 0 { return "Expired \(expiresAt.formatted(date: .abbreviated, time: .omitted))" }
        if days == 0 { return "Expires today" }
        if days <= 30 { return "Expires in \(days) day\(days == 1 ? "" : "s")" }
        return "Expires \(expiresAt.formatted(date: .abbreviated, time: .omitted))"
    }

    /// Writes the file to a temporary location for previewing or sharing.
    func temporaryFileURL() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let name = fileName.isEmpty ? "Evidence" : fileName
        let url = folder.appendingPathComponent(name)
        try fileData.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }
}
