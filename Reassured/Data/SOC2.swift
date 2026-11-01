import Foundation

extension TemplateLibrary {
    /// A SOC 2 readiness self-assessment organized by the Trust Services Criteria categories.
    /// Questions are Reassured's own wording, not the AICPA's criteria text. A SOC 2 report can
    /// only be issued by a licensed CPA firm.
    static let soc2Readiness = ChecklistTemplate(
        id: "soc2-readiness",
        name: "SOC 2 Readiness",
        area: .serviceOrgs,
        summary: "Readiness questions organized by the SOC 2 Common Criteria (CC1 to CC9) plus the four optional categories.",
        source: "Organized by the Trust Services Criteria categories. Reassured's own wording.",
        groups: [
            TemplateGroup(name: "Control Environment (CC1)", items: [
                TemplateItem("CC1.a", "Is there a code of conduct staff acknowledge?", "Ask for the code of conduct and signed acknowledgments."),
                TemplateItem("CC1.b", "Does leadership or a board oversee security?", "Look for meeting minutes or reports showing oversight."),
                TemplateItem("CC1.c", "Are roles and reporting lines defined?", "Org chart and job descriptions include security responsibilities."),
                TemplateItem("CC1.d", "Are new hires background checked?", "Check the hiring process for screening steps."),
            ]),
            TemplateGroup(name: "Communication and Information (CC2)", items: [
                TemplateItem("CC2.a", "Are security policies published to staff?", "Policies are easy to find and staff know where they are."),
                TemplateItem("CC2.b", "Is there a way to report security concerns?", "There's a channel for staff and customers to report issues."),
                TemplateItem("CC2.c", "Are customers told about commitments and changes?", "System descriptions, terms, and change notices are shared with customers."),
            ]),
            TemplateGroup(name: "Risk Assessment (CC3)", items: [
                TemplateItem("CC3.a", "Is there a formal risk assessment done at least yearly?", "Ask for the most recent risk assessment."),
                TemplateItem("CC3.b", "Does it consider fraud risk?", "The assessment covers the potential for fraud."),
                TemplateItem("CC3.c", "Are major changes assessed for risk?", "Changes like new vendors or systems trigger a risk review."),
            ]),
            TemplateGroup(name: "Monitoring Activities (CC4)", items: [
                TemplateItem("CC4.a", "Are controls tested or reviewed regularly?", "Internal audits, reviews, or automated monitoring check that controls work."),
                TemplateItem("CC4.b", "Are control gaps tracked to closure?", "Deficiencies are logged with owners and due dates."),
            ]),
            TemplateGroup(name: "Control Activities (CC5)", items: [
                TemplateItem("CC5.a", "Are controls chosen to address identified risks?", "There's a link between risks and the controls meant to handle them."),
                TemplateItem("CC5.b", "Are policies turned into procedures people follow?", "Procedures exist for key processes, not just policies."),
            ]),
            TemplateGroup(name: "Logical and Physical Access (CC6)", items: [
                TemplateItem("CC6.a", "Is access granted through an approval process?", "Access requests are approved and recorded."),
                TemplateItem("CC6.b", "Is access removed promptly when people leave?", "Check a few recent departures against account status."),
                TemplateItem("CC6.c", "Are user access reviews done periodically?", "Ask for the last access review and its sign-off."),
                TemplateItem("CC6.d", "Is MFA required for systems in scope?", "MFA covers production, cloud consoles, email, and remote access."),
                TemplateItem("CC6.e", "Is data encrypted in transit and at rest?", "Check TLS and storage encryption for in-scope systems."),
                TemplateItem("CC6.f", "Are offices and data centers physically secured?", "Badge access, visitor logs, and data center reports (for example, cloud provider SOC reports)."),
                TemplateItem("CC6.g", "Is endpoint protection on all company devices?", "EDR or antivirus, disk encryption, and device management are in place."),
            ]),
            TemplateGroup(name: "System Operations (CC7)", items: [
                TemplateItem("CC7.a", "Are systems monitored for security events?", "Logging and alerting cover in-scope systems."),
                TemplateItem("CC7.b", "Are vulnerabilities scanned and fixed?", "Scans run regularly and findings are remediated on time."),
                TemplateItem("CC7.c", "Is there a tested incident response plan?", "Ask for the plan and the last test or real incident record."),
            ]),
            TemplateGroup(name: "Change Management (CC8)", items: [
                TemplateItem("CC8.a", "Are changes reviewed and approved before release?", "Code reviews, change tickets, and approvals are recorded."),
                TemplateItem("CC8.b", "Are changes tested before production?", "Testing happens in a separate environment."),
                TemplateItem("CC8.c", "Can developers push to production without review?", "Check branch protection and deployment permissions."),
            ]),
            TemplateGroup(name: "Risk Mitigation (CC9)", items: [
                TemplateItem("CC9.a", "Are vendors assessed before and during use?", "Vendor security reviews and their SOC reports are on file."),
                TemplateItem("CC9.b", "Is there business continuity and insurance coverage?", "Continuity plans and cyber insurance are in place."),
            ]),
            TemplateGroup(name: "Availability (Optional)", items: [
                TemplateItem("A.a", "Are backups taken and restore-tested?", "Ask for the last successful restore test."),
                TemplateItem("A.b", "Is there a tested disaster recovery plan?", "Recovery objectives are defined and tested."),
                TemplateItem("A.c", "Is capacity monitored?", "Alerts warn before systems run out of capacity."),
            ]),
            TemplateGroup(name: "Confidentiality (Optional)", items: [
                TemplateItem("C.a", "Is confidential data identified and classified?", "A data classification scheme is used."),
                TemplateItem("C.b", "Is confidential data disposed of securely?", "Retention and disposal procedures are followed."),
            ]),
            TemplateGroup(name: "Processing Integrity (Optional)", items: [
                TemplateItem("PI.a", "Are inputs and outputs validated?", "Processing checks catch errors and incomplete data."),
                TemplateItem("PI.b", "Are processing errors detected and corrected?", "Errors are logged, investigated, and fixed."),
            ]),
            TemplateGroup(name: "Privacy (Optional)", items: [
                TemplateItem("P.a", "Is there a privacy notice?", "The notice explains what's collected and why."),
                TemplateItem("P.b", "Can people access or delete their data?", "There's a process for data subject requests."),
                TemplateItem("P.c", "Is personal data kept only as long as needed?", "Retention periods are defined and enforced."),
            ]),
        ],
        isReadinessLevel: true
    )
}
