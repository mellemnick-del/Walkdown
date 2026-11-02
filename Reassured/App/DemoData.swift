#if DEBUG
import Foundation
import SwiftData
import UIKit
import UniformTypeIdentifiers

/// Sample data for screenshots and demos. Debug builds only, so it can never ship to customers.
/// Launch with `-demo`, and optionally `-screen home|audits|workspace|tasks|locker|library|clients`.
enum DemoData {
    static var isEnabled: Bool { ProcessInfo.processInfo.arguments.contains("-demo") }

    static var screen: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-screen"), index + 1 < args.count else { return nil }
        return args[index + 1]
    }

    /// Fixes Home's sky for screenshots: -sky dawn|day|dusk|night.
    static var sky: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-sky"), index + 1 < args.count else { return nil }
        return args[index + 1]
    }

    static func seed(_ context: ModelContext) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: SettingsKeys.hasOnboarded)
        defaults.set(false, forKey: SettingsKeys.requireFaceID)
        defaults.set("Nick Mellem", forKey: SettingsKeys.auditorName)
        defaults.set("Northline Advisory", forKey: SettingsKeys.companyName)
        defaults.set(UserRole.assessor.rawValue, forKey: SettingsKeys.userRole)
        ReminderScheduler.isEnabled = false

        let machining = Client(name: "Lone Star Machining", industry: "Defense Manufacturing")
        machining.contactName = "Dana Ortiz"
        machining.contactEmail = "dana@example.com"
        let clinic = Client(name: "Woodlands Family Clinic", industry: "Healthcare")
        let bank = Client(name: "Gulf Coast Credit Union", industry: "Financial Services")
        for client in [machining, clinic, bank] { context.insert(client) }

        // Main audit: CMMC Level 2, about 70% done, with a realistic mix of results.
        let cmmc = make(TemplateLibrary.cmmcLevel2, client: machining, kind: .onSite, daysAgo: 2, context: context)
        apply(to: cmmc, answered: 0.72, seed: 3)
        addFinding(to: cmmc, controlID: "IA 3.5.3", title: "MFA not enforced for remote access",
                   severity: .critical, detail: "VPN accepts password-only logins for 14 of 52 users.",
                   recommendation: "Require MFA on the VPN for all users and disable the legacy profile.", context: context)
        addFinding(to: cmmc, controlID: "PE 3.10.3", title: "Visitors not escorted on the shop floor",
                   severity: .high, detail: "Two vendor technicians walked unescorted past the CNC area.",
                   recommendation: "Require escorts and visitor badges beyond the lobby.", context: context)
        addFinding(to: cmmc, controlID: "MP 3.8.3", title: "Retired drives stored without wiping",
                   severity: .medium, detail: "A bin of 11 retired drives sits in the IT closet.",
                   recommendation: "Wipe or shred the drives and keep certificates of destruction.", context: context)
        RemediationPlanner.buildPlan(for: cmmc, in: context)
        // A couple of overdue and finished tasks so the lists look lived in.
        let tasks = (cmmc.tasks ?? []).sorted(by: RemediationTask.nextUp)
        if tasks.count > 3 {
            tasks[0].dueDate = Calendar.current.date(byAdding: .day, value: -3, to: .now)
            tasks[0].owner = "Dana"
            tasks[1].dueDate = Calendar.current.date(byAdding: .day, value: 4, to: .now)
            tasks[1].owner = "Marcus"
            tasks[2].state = .done
        }

        let hipaa = make(TemplateLibrary.hipaaSecurity, client: clinic, kind: .onSite, daysAgo: 21, context: context)
        apply(to: hipaa, answered: 1.0, seed: 1)
        hipaa.status = .complete

        let soc2 = make(TemplateLibrary.soc2Readiness, client: nil, kind: .selfAssessment, daysAgo: 6, context: context)
        soc2.clientName = "Northline Advisory"
        apply(to: soc2, answered: 0.4, seed: 5)

        let pci = make(TemplateLibrary.pciDSS, client: bank, kind: .onSite, daysAgo: 9, context: context)
        apply(to: pci, answered: 0.3, seed: 7)

        // Evidence Locker
        addEvidence("MFA Configuration Screenshot", kind: .screenshot, topics: [.mfa, .accessControl],
                    expiresIn: 12, client: machining, link: [cmmc], ids: ["IA 3.5.3", "AC 3.1.12"], context: context)
        addEvidence("Incident Response Plan v3", kind: .policy, topics: [.incidentResponse, .policies],
                    expiresIn: 210, client: machining, link: [cmmc], ids: ["IR 3.6.1"], context: context)
        addEvidence("Penetration Test Report 2025", kind: .report, topics: [.vulnerability],
                    expiresIn: -5, client: machining, link: [cmmc], ids: ["RA 3.11.2"], context: context)
        addEvidence("Security Awareness Training Records", kind: .training, topics: [.training],
                    expiresIn: 45, client: machining, link: [cmmc], ids: ["AT 3.2.1"], context: context)
        addEvidence("Business Associate Agreements", kind: .contract, topics: [.vendors],
                    expiresIn: 300, client: clinic, link: [hipaa], ids: ["164.308(b)(1)"], context: context)
        addEvidence("Cyber Insurance Certificate", kind: .certificate, topics: [.continuity],
                    expiresIn: 26, client: nil, link: [], ids: [], context: context)

        AuditWriter.saveSummary("""
            Lone Star Machining has a solid foundation for protecting Controlled Unclassified Information, \
            scoring 77% across the 79 requirements reviewed so far. Access control, configuration management, \
            and malware protection are largely in place.

            The most urgent gap is multifactor authentication: remote access still accepts password-only \
            logins for some users. Fixing that first, then escorting visitors on the shop floor and wiping \
            retired drives, will close the highest risks ahead of a CMMC Level 2 assessment.
            """, for: cmmc)

        // Make the CMMC audit the most recent activity so Home features it.
        for (index, control) in cmmc.sortedControls.enumerated() where control.status != .notStarted {
            control.updatedAt = Calendar.current.date(byAdding: .second, value: index, to: .now) ?? .now
        }

        try? context.save()
    }

    private static func make(_ template: ChecklistTemplate, client: Client?, kind: AuditKind,
                             daysAgo: Int, context: ModelContext) -> Audit {
        AuditFactory.create(from: template, clientName: client?.name ?? "", siteName: "",
                            location: client == nil ? "" : "The Woodlands, TX", auditorName: "Nick Mellem",
                            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now,
                            scopeNotes: "", kind: kind, client: client, in: context)
    }

    /// Answers a share of controls with a fixed, repeatable pattern.
    private static func apply(to audit: Audit, answered share: Double, seed: Int) {
        let controls = audit.sortedControls
        let cutoff = Int(Double(controls.count) * share)
        let pattern: [ControlStatus] = [.pass, .pass, .pass, .partial, .pass, .fail, .pass, .pass, .notApplicable, .pass, .pass, .partial]
        for (index, control) in controls.enumerated() where index < cutoff {
            control.status = pattern[(index + seed) % pattern.count]
            control.updatedAt = Calendar.current.date(byAdding: .minute, value: -index, to: .now) ?? .now
            if control.status == .fail {
                control.notes = "Observed on site. Owner says a fix is planned but there's no ticket yet."
            }
        }
    }

    private static func addFinding(to audit: Audit, controlID: String, title: String, severity: Severity,
                                   detail: String, recommendation: String, context: ModelContext) {
        let finding = Finding(title: title, detail: detail, recommendation: recommendation, severity: severity)
        context.insert(finding)
        finding.audit = audit
        if let control = audit.sortedControls.first(where: { $0.controlID == controlID }) {
            control.status = .fail
            finding.control = control
        }
    }

    private static func addEvidence(_ title: String, kind: EvidenceKind, topics: Set<EvidenceTopic>, expiresIn days: Int,
                                    client: Client?, link audits: [Audit], ids: [String], context: ModelContext) {
        let item = LockerItem(title: title, fileData: Data("Reassured demo file".utf8),
                              fileName: "\(title).pdf", contentType: .pdf, kind: kind)
        context.insert(item)
        item.topics = topics
        item.client = client
        item.expiresAt = Calendar.current.date(byAdding: .day, value: days, to: .now)
        for audit in audits {
            for control in audit.sortedControls where ids.contains(control.controlID) {
                if control.lockerItems == nil { control.lockerItems = [] }
                control.lockerItems?.append(item)
            }
        }
    }
}
#endif
