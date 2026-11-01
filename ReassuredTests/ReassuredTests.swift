import Foundation
import SwiftData
import Testing
import UniformTypeIdentifiers
@testable import Reassured

@MainActor
struct ScoringTests {
    private func controls(_ statuses: [ControlStatus]) -> [ControlResult] {
        statuses.enumerated().map { index, status in
            let control = ControlResult(controlID: "T-\(index)", title: "Test", guidance: "", groupName: "G", groupOrder: 0, order: index)
            control.status = status
            return control
        }
    }

    @Test func noScoreUntilSomethingIsAnswered() {
        #expect(ComplianceScore.score(for: controls([.notStarted, .notApplicable])) == nil)
    }

    @Test func passCountsFullyAndPartialCountsHalf() {
        // 1 + 0.5 + 0 out of 3 scored controls; N/A and Not Started are left out.
        let score = ComplianceScore.score(for: controls([.pass, .partial, .fail, .notApplicable, .notStarted]))
        #expect(score == 0.5)
    }

    @Test func allPassIsOneHundredPercent() {
        #expect(ComplianceScore.score(for: controls([.pass, .pass])) == 1)
    }
}

struct TemplateTests {
    @Test func cmmcLevel2HasAll110Requirements() {
        #expect(TemplateLibrary.cmmcLevel2.itemCount == 110)
    }

    @Test func cmmcLevel1Has17Practices() {
        #expect(TemplateLibrary.cmmcLevel1.itemCount == 17)
    }

    @Test(arguments: TemplateLibrary.all)
    func controlIDsAreUniqueWithinEachChecklist(template: ChecklistTemplate) {
        let ids = template.groups.flatMap(\.items).map(\.id)
        #expect(Set(ids).count == ids.count, "Duplicate control ID in \(template.name)")
    }

    @Test func templateIDsAreUnique() {
        let ids = TemplateLibrary.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}

@MainActor
struct AuditTests {
    private func makeAudit(_ context: ModelContext) -> Audit {
        AuditFactory.create(from: TemplateLibrary.cmmcLevel1, clientName: "Test Co", siteName: "", location: "",
                            auditorName: "Tester", date: .now, scopeNotes: "", kind: .onSite, in: context)
    }

    @Test func creatingAnAuditCopiesEveryControl() throws {
        let container = try ReassuredStore.makeContainer(inMemory: true)
        let audit = makeAudit(container.mainContext)
        #expect(audit.totalCount == 17)
        #expect(audit.answeredCount == 0)
        #expect(audit.progress == 0)
    }

    @Test func remediationPlanCoversFailAndPartialOnce() throws {
        ReminderScheduler.isEnabled = false
        let container = try ReassuredStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let audit = makeAudit(context)
        let controls = audit.sortedControls
        controls[0].status = .fail
        controls[1].status = .partial
        controls[2].status = .pass

        #expect(RemediationPlanner.buildPlan(for: audit, in: context) == 2)
        // Running it again doesn't duplicate tasks.
        #expect(RemediationPlanner.buildPlan(for: audit, in: context) == 0)

        let tasks = audit.tasks ?? []
        #expect(tasks.first { $0.control === controls[0] }?.priority == .high)
        #expect(tasks.first { $0.control === controls[1] }?.priority == .medium)
    }

    @Test func findingSeveritySetsTaskPriority() throws {
        ReminderScheduler.isEnabled = false
        let container = try ReassuredStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let audit = makeAudit(context)
        let control = audit.sortedControls[0]
        control.status = .fail
        let finding = Finding(title: "Critical issue", severity: .critical)
        context.insert(finding)
        finding.audit = audit
        finding.control = control

        RemediationPlanner.buildPlan(for: audit, in: context)
        #expect(audit.tasks?.first?.priority == .critical)
    }
}

@MainActor
struct BackupTests {
    @Test func backupRoundTripRestoresEverything() throws {
        ReminderScheduler.isEnabled = false
        let source = try ReassuredStore.makeContainer(inMemory: true)
        let context = source.mainContext

        let client = Client(name: "Lone Star", industry: "Manufacturing")
        context.insert(client)
        let audit = AuditFactory.create(from: TemplateLibrary.hipaaSecurity, clientName: "Lone Star", siteName: "",
                                        location: "", auditorName: "Tester", date: .now, scopeNotes: "Main office",
                                        kind: .onSite, client: client, in: context)
        let control = audit.sortedControls[0]
        control.status = .fail
        control.notes = "No risk analysis on file."
        let evidence = Evidence(imageData: Data([1, 2, 3]), caption: "Photo")
        context.insert(evidence)
        evidence.control = control
        let finding = Finding(title: "Missing risk analysis", severity: .high)
        context.insert(finding)
        finding.audit = audit
        finding.control = control
        let item = LockerItem(title: "Policy", fileData: Data("pdf".utf8), fileName: "Policy.pdf", contentType: .pdf, kind: .policy)
        context.insert(item)
        item.client = client
        control.lockerItems = [item]
        RemediationPlanner.buildPlan(for: audit, in: context)

        let data = try BackupService.encode(try BackupService.makeBackup(in: context))

        let destination = try ReassuredStore.makeContainer(inMemory: true)
        let restored = destination.mainContext
        let summary = try BackupService.importBackup(try BackupService.decode(data), into: restored)
        #expect(summary.audits == 1)
        #expect(summary.clients == 1)
        #expect(summary.lockerItems == 1)

        let audits = try restored.fetch(FetchDescriptor<Audit>())
        let copy = try #require(audits.first)
        #expect(copy.id == audit.id)
        #expect(copy.client?.name == "Lone Star")
        #expect(copy.totalCount == audit.totalCount)
        let copiedControl = try #require(copy.sortedControls.first)
        #expect(copiedControl.status == .fail)
        #expect(copiedControl.notes == "No risk analysis on file.")
        #expect(copiedControl.evidence?.first?.imageData == Data([1, 2, 3]))
        #expect(copiedControl.lockerItems?.first?.title == "Policy")
        #expect(copy.findings?.first?.control?.controlID == control.controlID)
        #expect(copy.tasks?.count == 1)

        // Importing the same backup again adds nothing.
        let again = try BackupService.importBackup(try BackupService.decode(data), into: restored)
        #expect(again.audits == 0)
        #expect(again.skipped == 3)
    }

    @Test func rejectsBackupsFromNewerVersions() throws {
        var backup = BackupService.BackupFile(version: BackupService.currentVersion + 1, exportedAt: .now,
                                              clients: [], audits: [], lockerItems: [])
        backup.version = BackupService.currentVersion + 1
        let data = try BackupService.encode(backup)
        #expect(throws: BackupService.BackupError.self) { try BackupService.decode(data) }
    }
}
