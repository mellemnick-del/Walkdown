import Foundation

extension TemplateLibrary {
    /// NIST SP 800-53 Rev 5 at the control family level (20 families). US government work.
    /// Guidance is Reassured's own wording.
    static let nist80053 = ChecklistTemplate(
        id: "nist-800-53-r5",
        name: "NIST 800-53 Rev 5 (Families)",
        area: .federal,
        summary: "The 20 control families of NIST SP 800-53 Rev 5, used by FedRAMP, FISMA, and many state programs.",
        source: "NIST SP 800-53 Rev 5",
        groups: [
            TemplateGroup(name: "Governance and Planning", items: [
                TemplateItem("PL", "Planning", "System security and privacy plans exist, are current, and rules of behavior are signed."),
                TemplateItem("PM", "Program Management", "An organization-wide security program has leadership, a strategy, and resources."),
                TemplateItem("RA", "Risk Assessment", "Risk assessments, system categorization, and vulnerability scanning happen on a schedule."),
                TemplateItem("CA", "Assessment, Authorization, and Monitoring", "Controls are assessed, systems are authorized to operate, POA&Ms are tracked, and monitoring is continuous."),
                TemplateItem("SA", "System and Services Acquisition", "Security requirements are in contracts and the development lifecycle."),
                TemplateItem("SR", "Supply Chain Risk Management", "Suppliers and components are assessed, and there's a supply chain risk plan."),
                TemplateItem("PT", "PII Processing and Transparency", "Personal data is processed only with authority, purpose, and notice."),
            ]),
            TemplateGroup(name: "Operations and People", items: [
                TemplateItem("AT", "Awareness and Training", "Security and privacy training is delivered and tracked, including role-based training."),
                TemplateItem("PS", "Personnel Security", "Screening, access agreements, and termination and transfer procedures are followed."),
                TemplateItem("CM", "Configuration Management", "Baselines, change control, inventories, and least functionality are in place."),
                TemplateItem("CP", "Contingency Planning", "Contingency plans, backups, alternate sites, and recovery testing are in place."),
                TemplateItem("IR", "Incident Response", "Incident plans, handling, reporting, and testing are in place."),
                TemplateItem("MA", "Maintenance", "Maintenance is controlled, including tools, remote maintenance, and personnel."),
                TemplateItem("MP", "Media Protection", "Media is protected, marked, transported securely, and sanitized."),
                TemplateItem("PE", "Physical and Environmental Protection", "Physical access, monitoring, visitor control, power, fire, and water protections are in place."),
            ]),
            TemplateGroup(name: "Technical", items: [
                TemplateItem("AC", "Access Control", "Account management, least privilege, session controls, and remote and wireless access are controlled."),
                TemplateItem("IA", "Identification and Authentication", "Users and devices are uniquely identified, MFA is used, and authenticators are managed."),
                TemplateItem("AU", "Audit and Accountability", "Events are logged, protected, reviewed, and retained."),
                TemplateItem("SC", "System and Communications Protection", "Boundaries are protected, data is encrypted in transit and at rest, and keys are managed."),
                TemplateItem("SI", "System and Information Integrity", "Flaws are remediated, malware is blocked, and systems are monitored."),
            ]),
        ],
        isReadinessLevel: true
    )
}
