import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Writing help from Apple's on-device model (iOS 26+, Apple Intelligence devices).
/// Runs entirely on the iPhone, so client details never leave the device.
enum AuditWriter {
    struct FindingDraft {
        var title: String
        var detail: String
        var recommendation: String
        var severity: Severity
    }

    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    /// Turns a control and the auditor's rough notes into a finding.
    static func draftFinding(for control: ControlResult, framework: String) async -> FindingDraft? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await ModelWriter.draftFinding(
                controlID: control.controlID, title: control.title, guidance: control.guidance,
                notes: control.notes, status: control.status.label, framework: framework)
        }
        #endif
        return nil
    }

    /// A short executive summary for the report.
    static func executiveSummary(for audit: Audit) async -> String? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await ModelWriter.summary(of: audit)
        }
        #endif
        return nil
    }

    // Executive summaries are kept per audit on this device.
    static func savedSummary(for audit: Audit) -> String {
        UserDefaults.standard.string(forKey: "summary-\(audit.id.uuidString)") ?? ""
    }

    static func saveSummary(_ text: String, for audit: Audit) {
        UserDefaults.standard.set(text, forKey: "summary-\(audit.id.uuidString)")
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
private enum ModelWriter {
    @Generable
    enum Level { case critical, high, medium, low }

    @Generable
    struct Finding {
        @Guide(description: "A short finding title of at most 10 words, stating the problem plainly.")
        var title: String
        @Guide(description: "Two or three sentences: what was observed and why it matters. Use only facts from the notes. Do not invent numbers, names, or details.")
        var detail: String
        @Guide(description: "One to three sentences with specific, practical steps to fix it.")
        var recommendation: String
        @Guide(description: "critical: active exposure of sensitive data or no control at all on a key safeguard. high: a key control missing or failing. medium: partly in place. low: minor gap or documentation issue.")
        var severity: Level
    }

    static func draftFinding(controlID: String, title: String, guidance: String, notes: String,
                             status: String, framework: String) async -> AuditWriter.FindingDraft? {
        let session = LanguageModelSession(instructions: """
            You help a security auditor write clear, professional audit findings. Write in plain English \
            for a business owner. Be factual and calm. Never invent facts that aren't in the notes.
            """)
        let prompt = """
            Framework: \(framework)
            Control: \(controlID) \(title)
            What the control expects: \(guidance)
            Result: \(status)
            Auditor's notes: \(notes.isEmpty ? "(none)" : notes)
            """
        guard let response = try? await session.respond(to: prompt, generating: Finding.self) else { return nil }
        let finding = response.content
        let severity: Severity = switch finding.severity {
        case .critical: .critical
        case .high: .high
        case .medium: .medium
        case .low: .low
        }
        return AuditWriter.FindingDraft(title: finding.title, detail: finding.detail,
                                        recommendation: finding.recommendation, severity: severity)
    }

    static func summary(of audit: Audit) async -> String? {
        let session = LanguageModelSession(instructions: """
            You write executive summaries for security audit reports. Write one or two short paragraphs \
            for a business owner: overall posture, the most important risks, and what to do first. \
            Be calm, clear, and encouraging. Use only the facts given. No headings or bullet points.
            """)
        let findings = audit.sortedFindings.prefix(8).map { "- \($0.severity.label): \($0.title)" }.joined(separator: "\n")
        let weakest = areaScores(audit).sorted { $0.1 < $1.1 }.prefix(3)
            .map { "\($0.0) \(Int(($0.1 * 100).rounded()))%" }.joined(separator: ", ")
        let prompt = """
            Organization: \(audit.displayName)
            Checklist: \(audit.checklistName)
            Overall score: \(audit.score.map { "\(Int(($0 * 100).rounded()))%" } ?? "not scored")
            Controls answered: \(audit.answeredCount) of \(audit.totalCount)
            Results: \(audit.count(.pass)) pass, \(audit.count(.partial)) partial, \(audit.count(.fail)) fail
            Weakest areas: \(weakest.isEmpty ? "none" : weakest)
            Findings:
            \(findings.isEmpty ? "none recorded" : findings)
            """
        return try? await session.respond(to: prompt).content
    }

    private static func areaScores(_ audit: Audit) -> [(String, Double)] {
        var names: [String] = []
        for control in audit.sortedControls where !names.contains(control.groupName) { names.append(control.groupName) }
        return names.compactMap { name in
            ComplianceScore.score(for: audit.sortedControls.filter { $0.groupName == name }).map { (name, $0) }
        }
    }
}
#endif
