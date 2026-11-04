import Foundation
import SwiftData
import Testing
import UniformTypeIdentifiers
import PDFKit
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

    @Test(arguments: TemplateLibrary.all.map(\.id))
    func controlIDsAreUniqueWithinEachChecklist(templateID: String) throws {
        let template = try #require(TemplateLibrary.template(id: templateID))
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

@MainActor
struct ReportTests {
    @Test func reportBuildsAllSections() throws {
        ReminderScheduler.isEnabled = false
        let container = try ReassuredStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let audit = AuditFactory.create(from: TemplateLibrary.cmmcLevel1, clientName: "Test Co", siteName: "HQ",
                                        location: "Houston, TX", auditorName: "Tester", date: .now,
                                        scopeNotes: "All systems that handle FCI.", kind: .onSite, in: context)
        for (index, control) in audit.sortedControls.enumerated() {
            control.status = [.pass, .partial, .fail, .notApplicable][index % 4]
            control.notes = index % 3 == 0 ? "Observed on site." : ""
        }
        let finding = Finding(title: "No MFA on VPN", detail: "Password-only logins.", recommendation: "Require MFA.", severity: .critical)
        context.insert(finding)
        finding.audit = audit
        finding.control = audit.sortedControls.first { $0.status == .fail }
        RemediationPlanner.buildPlan(for: audit, in: context)

        let data = ReportBuilder.makePDFData(for: audit, companyName: "Northline Advisory", summary: "Solid start.")
        let document = try #require(PDFDocument(data: data))
        // Cover, summary, findings, remediation plan, and at least one page of control results.
        #expect(document.pageCount >= 5)
        let text = document.string ?? ""
        #expect(text.contains("Executive Summary"))
        #expect(text.contains("Remediation Plan"))
        #expect(text.contains("No MFA on VPN"))
    }
}

struct MilestoneTests {
    @Test func nothingEarnedAtTheStart() {
        #expect(Milestones.earned(MilestoneStats()).isEmpty)
    }

    @Test func progressCountsTowardGoalsAndCaps() {
        var stats = MilestoneStats()
        stats.answeredControls = 140
        let centurion = try! #require(Milestones.all.first { $0.id == "centurion" })
        let thousand = try! #require(Milestones.all.first { $0.id == "thousand-checks" })
        #expect(Milestones.progress(centurion, stats) == 100)
        #expect(Milestones.progress(thousand, stats) == 140)
        let earned = Set(Milestones.earned(stats).map(\.id))
        #expect(earned == ["first-steps", "centurion"])
    }

    @Test func scoreMilestones() {
        var stats = MilestoneStats()
        stats.bestScore = 0.82
        stats.bestCompleteScore = 0.96
        let earned = Set(Milestones.earned(stats).map(\.id))
        #expect(earned.contains("strong-score"))
        #expect(earned.contains("gold-standard"))
    }

    @Test func milestoneIDsAreUnique() {
        let ids = Milestones.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @MainActor
    @Test func statsFromRealData() throws {
        ReminderScheduler.isEnabled = false
        let container = try ReassuredStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let audit = AuditFactory.create(from: TemplateLibrary.cmmcLevel1, clientName: "Test", siteName: "", location: "",
                                        auditorName: "", date: .now, scopeNotes: "", kind: .onSite, in: context)
        for control in audit.sortedControls { control.status = .pass }
        audit.status = .complete
        let stats = MilestoneStats(audits: [audit], tasks: [], lockerItems: [], clients: [], walkAnswers: 0, reportsOpened: 0)
        #expect(stats.answeredControls == 17)
        #expect(stats.completedAudits == 1)
        #expect(stats.cmmcCompleted)
        #expect(stats.bestCompleteScore == 1)
        let earned = Set(Milestones.earned(stats).map(\.id))
        #expect(earned.isSuperset(of: ["first-steps", "first-light", "strong-score", "defense-ready", "gold-standard"]))
    }
}

@MainActor
struct CertificateTests {
    @Test func certificateIsOneLandscapePageWithTheOrganization() throws {
        ReminderScheduler.isEnabled = false
        let container = try ReassuredStore.makeContainer(inMemory: true)
        let audit = AuditFactory.create(from: TemplateLibrary.hipaaSecurity, clientName: "Woodlands Family Clinic",
                                        siteName: "", location: "", auditorName: "Tester", date: .now, scopeNotes: "",
                                        kind: .onSite, in: container.mainContext)
        for control in audit.sortedControls { control.status = .pass }
        audit.status = .complete

        let data = CertificateBuilder.makePDFData(for: audit, companyName: "Northline Advisory", options: .init())
        let document = try #require(PDFDocument(data: data))
        #expect(document.pageCount == 1)
        let bounds = try #require(document.page(at: 0)).bounds(for: .mediaBox)
        #expect(bounds.width > bounds.height)
        let text = document.string ?? ""
        #expect(text.contains("Woodlands Family Clinic"))
        #expect(text.contains("100%"))
        #expect(text.contains(CertificateBuilder.certificateID(for: audit)))
    }

    @Test func scoreCanBeLeftOff() throws {
        ReminderScheduler.isEnabled = false
        let container = try ReassuredStore.makeContainer(inMemory: true)
        let audit = AuditFactory.create(from: TemplateLibrary.cmmcLevel1, clientName: "Test Co", siteName: "", location: "",
                                        auditorName: "", date: .now, scopeNotes: "", kind: .selfAssessment, in: container.mainContext)
        for control in audit.sortedControls { control.status = .pass }
        let data = CertificateBuilder.makePDFData(for: audit, companyName: "", options: .init(includeScore: false))
        let text = PDFDocument(data: data)?.string ?? ""
        #expect(!text.contains("overall score"))
        #expect(text.contains("self-assessment"))
    }
}

@MainActor
struct RecentlyDeletedTests {
    private func makeAudit(_ context: ModelContext, status: AuditStatus = .complete) -> Audit {
        let audit = AuditFactory.create(from: TemplateLibrary.cmmcLevel1, clientName: "Trash Test", siteName: "", location: "",
                                        auditorName: "", date: .now, scopeNotes: "", kind: .onSite, in: context)
        audit.sortedControls.first?.status = .fail
        audit.status = status
        return audit
    }

    @Test func deleteHidesAndRestoreBringsItBack() throws {
        ReminderScheduler.isEnabled = false
        let container = try ReassuredStore.makeContainer(inMemory: true)
        let audit = makeAudit(container.mainContext, status: .complete)

        RecentlyDeleted.delete(audit)
        #expect(audit.isInTrash)
        #expect(RecentlyDeleted.daysLeft(audit) == RecentlyDeleted.keepDays)
        #expect(MilestoneStats(audits: [audit], tasks: [], lockerItems: [], clients: [], walkAnswers: 0, reportsOpened: 0).answeredControls == 0)

        RecentlyDeleted.restore(audit)
        #expect(!audit.isInTrash)
        #expect(audit.status == .complete)
        #expect(audit.sortedControls.first?.status == .fail)
    }

    @Test func purgeOnlyRemovesAuditsOlderThan30Days() throws {
        ReminderScheduler.isEnabled = false
        let container = try ReassuredStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let old = makeAudit(context)
        let recent = makeAudit(context)
        let now = Date.now
        RecentlyDeleted.delete(old, now: now.addingTimeInterval(-31 * 86_400))
        RecentlyDeleted.delete(recent, now: now.addingTimeInterval(-5 * 86_400))

        #expect(RecentlyDeleted.purge(in: context, now: now) == 1)
        let remaining = try context.fetch(FetchDescriptor<Audit>()).map(\.id)
        #expect(remaining.contains(recent.id))
        #expect(!remaining.contains(old.id))
        #expect(RecentlyDeleted.daysLeft(recent, now: now) == 25)
    }

    @Test func backupsLeaveOutDeletedAudits() throws {
        ReminderScheduler.isEnabled = false
        let container = try ReassuredStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let kept = makeAudit(context)
        let trashed = makeAudit(context)
        RecentlyDeleted.delete(trashed)
        let backup = try BackupService.makeBackup(in: context)
        #expect(backup.audits.map(\.id) == [kept.id])
    }
}

@MainActor
struct EarlyScoreTests {
    @Test func noScoreUntilFiveAnswers() throws {
        ReminderScheduler.isEnabled = false
        let container = try ReassuredStore.makeContainer(inMemory: true)
        let audit = AuditFactory.create(from: TemplateLibrary.soc2Readiness, clientName: "Early", siteName: "", location: "",
                                        auditorName: "", date: .now, scopeNotes: "", kind: .selfAssessment, in: container.mainContext)
        let controls = audit.sortedControls
        controls[0].status = .pass
        controls[1].status = .pass
        controls[2].status = .notApplicable
        #expect(audit.score == nil)
        for control in controls[3..<6] { control.status = .pass }
        #expect(audit.score == 1)
    }

    @Test func shortChecklistsScoreWhenEverythingIsAnswered() throws {
        ReminderScheduler.isEnabled = false
        let container = try ReassuredStore.makeContainer(inMemory: true)
        let audit = AuditFactory.create(from: TemplateLibrary.cmmcLevel1, clientName: "Short", siteName: "", location: "",
                                        auditorName: "", date: .now, scopeNotes: "", kind: .onSite, in: container.mainContext)
        // Mark all but three as N/A, then answer those three: every scorable control is answered.
        let controls = audit.sortedControls
        for control in controls.dropLast(3) { control.status = .notApplicable }
        for control in controls.suffix(3) { control.status = .pass }
        #expect(audit.score == 1)
    }
}
