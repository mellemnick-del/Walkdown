import Foundation

extension TemplateLibrary {
    /// An original IT General Controls (ITGC) checklist, the core of most IT and SOX audits.
    static let itGeneralControls = ChecklistTemplate(
        id: "itgc",
        name: "IT General Controls",
        area: .general,
        summary: "The four classic ITGC areas: access, change management, operations, and development.",
        source: "Walkdown original checklist",
        groups: [
            TemplateGroup(name: "Access to Programs and Data", items: [
                TemplateItem("ITGC-1.1", "New access is requested and approved", "Pick a few recent hires and confirm there's an approved request for each account."),
                TemplateItem("ITGC-1.2", "Access is removed on termination", "Compare a list of recent departures against active accounts."),
                TemplateItem("ITGC-1.3", "User access is reviewed periodically", "Ask for the last access review, who signed off, and what was changed."),
                TemplateItem("ITGC-1.4", "Privileged access is limited and monitored", "Review admin and database admin accounts and how their activity is logged."),
                TemplateItem("ITGC-1.5", "Password and MFA settings meet policy", "Check domain and application settings against the written policy."),
                TemplateItem("ITGC-1.6", "Generic and service accounts are controlled", "Shared and service accounts have owners and can't be used to log in interactively."),
            ]),
            TemplateGroup(name: "Change Management", items: [
                TemplateItem("ITGC-2.1", "Changes are requested, tested, and approved", "Sample changes and confirm each has a ticket, testing evidence, and approval."),
                TemplateItem("ITGC-2.2", "Developers can't move their own changes to production", "Check who can deploy to production."),
                TemplateItem("ITGC-2.3", "Emergency changes are reviewed after the fact", "Emergency changes get documented and approved afterward."),
                TemplateItem("ITGC-2.4", "Configuration changes are tracked", "Changes to servers, network gear, and cloud settings are logged."),
            ]),
            TemplateGroup(name: "Computer Operations", items: [
                TemplateItem("ITGC-3.1", "Backups run and are monitored", "Backup jobs are scheduled, and failures are followed up."),
                TemplateItem("ITGC-3.2", "Restores are tested", "Ask for the last restore test."),
                TemplateItem("ITGC-3.3", "Scheduled jobs are controlled", "Changes to batch jobs are approved, and failures are handled."),
                TemplateItem("ITGC-3.4", "Incidents and problems are tracked", "A ticketing process logs and resolves IT incidents."),
            ]),
            TemplateGroup(name: "Program Development", items: [
                TemplateItem("ITGC-4.1", "New systems follow a development lifecycle", "Projects have requirements, testing, and sign-off."),
                TemplateItem("ITGC-4.2", "Data migrations are validated", "Data moved to new systems is checked for completeness and accuracy."),
                TemplateItem("ITGC-4.3", "Users approve before go-live", "Business owners sign off on testing before launch."),
            ]),
        ]
    )
}
