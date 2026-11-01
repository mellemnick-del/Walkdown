import Foundation

extension TemplateLibrary {
    /// NIST Cybersecurity Framework 2.0 at the category level.
    /// Category IDs and names follow NIST CSF 2.0 (a US government work). Guidance is Reassured's own wording.
    static let nistCSF = ChecklistTemplate(
        id: "nist-csf-2",
        name: "NIST CSF 2.0 (Categories)",
        area: .general,
        summary: "The 22 categories of the NIST Cybersecurity Framework 2.0, grouped by its six functions.",
        source: "NIST Cybersecurity Framework 2.0",
        groups: [
            TemplateGroup(name: "Govern", items: [
                TemplateItem(id: "GV.OC", title: "Organizational Context",
                             guidance: "Leadership understands the mission, stakeholders, and legal requirements that shape security decisions."),
                TemplateItem(id: "GV.RM", title: "Risk Management Strategy",
                             guidance: "Risk appetite and priorities are written down and used to make security decisions."),
                TemplateItem(id: "GV.RR", title: "Roles, Responsibilities, and Authorities",
                             guidance: "Someone owns security, roles are assigned, and leadership is accountable."),
                TemplateItem(id: "GV.PO", title: "Policy",
                             guidance: "Security policies exist, are approved, communicated to staff, and reviewed on a schedule."),
                TemplateItem(id: "GV.OV", title: "Oversight",
                             guidance: "Results of the security program are reviewed and used to adjust strategy."),
                TemplateItem(id: "GV.SC", title: "Cybersecurity Supply Chain Risk Management",
                             guidance: "Vendors and suppliers are assessed, contracts include security terms, and critical suppliers are tracked."),
            ]),
            TemplateGroup(name: "Identify", items: [
                TemplateItem(id: "ID.AM", title: "Asset Management",
                             guidance: "Hardware, software, data, and services are inventoried and prioritized by importance."),
                TemplateItem(id: "ID.RA", title: "Risk Assessment",
                             guidance: "Vulnerabilities and threats are identified, and risks are assessed and prioritized."),
                TemplateItem(id: "ID.IM", title: "Improvement",
                             guidance: "Lessons from assessments, tests, and incidents feed back into improvements."),
            ]),
            TemplateGroup(name: "Protect", items: [
                TemplateItem(id: "PR.AA", title: "Identity Management, Authentication, and Access Control",
                             guidance: "Accounts are managed, MFA is used, access follows least privilege, and physical access is controlled."),
                TemplateItem(id: "PR.AT", title: "Awareness and Training",
                             guidance: "Staff receive security training, including role-specific training for privileged users."),
                TemplateItem(id: "PR.DS", title: "Data Security",
                             guidance: "Data is protected at rest and in transit, and backups are made, protected, and tested."),
                TemplateItem(id: "PR.PS", title: "Platform Security",
                             guidance: "Systems are hardened, patched, and configured securely, and logging is turned on."),
                TemplateItem(id: "PR.IR", title: "Technology Infrastructure Resilience",
                             guidance: "Networks are segmented, and capacity and redundancy support availability."),
            ]),
            TemplateGroup(name: "Detect", items: [
                TemplateItem(id: "DE.CM", title: "Continuous Monitoring",
                             guidance: "Networks, systems, users, and the physical environment are monitored for unusual activity."),
                TemplateItem(id: "DE.AE", title: "Adverse Event Analysis",
                             guidance: "Alerts are triaged and correlated, and incidents are declared using defined criteria."),
            ]),
            TemplateGroup(name: "Respond", items: [
                TemplateItem(id: "RS.MA", title: "Incident Management",
                             guidance: "An incident response plan exists, is followed, and incidents are tracked from start to finish."),
                TemplateItem(id: "RS.AN", title: "Incident Analysis",
                             guidance: "Incidents are investigated to find root cause and scope, and evidence is preserved."),
                TemplateItem(id: "RS.CO", title: "Incident Response Reporting and Communication",
                             guidance: "The right people, regulators, and partners are notified on time."),
                TemplateItem(id: "RS.MI", title: "Incident Mitigation",
                             guidance: "Incidents are contained and eradicated quickly."),
            ]),
            TemplateGroup(name: "Recover", items: [
                TemplateItem(id: "RC.RP", title: "Incident Recovery Plan Execution",
                             guidance: "Recovery plans are carried out, restored systems are checked, and recovery is declared complete."),
                TemplateItem(id: "RC.CO", title: "Incident Recovery Communication",
                             guidance: "Recovery progress is communicated to stakeholders and the public as needed."),
            ]),
        ]
    )
}
