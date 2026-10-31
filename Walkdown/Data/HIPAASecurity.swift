import Foundation

extension TemplateLibrary {
    /// HIPAA Security Rule standards (45 CFR Part 164, Subpart C). Guidance is Walkdown's own wording.
    static let hipaaSecurity = ChecklistTemplate(
        id: "hipaa-security",
        name: "HIPAA Security Rule",
        summary: "The administrative, physical, and technical safeguard standards of the HIPAA Security Rule.",
        source: "45 CFR 164.308, 164.310, 164.312",
        groups: [
            TemplateGroup(name: "Administrative Safeguards", items: [
                TemplateItem(id: "164.308(a)(1)", title: "Security Management Process",
                             guidance: "A current risk analysis exists, risks are being reduced, there is a sanctions policy, and system activity is reviewed."),
                TemplateItem(id: "164.308(a)(2)", title: "Assigned Security Responsibility",
                             guidance: "A named security official is responsible for the security program."),
                TemplateItem(id: "164.308(a)(3)", title: "Workforce Security",
                             guidance: "Staff access to ePHI is authorized, supervised, and removed when people leave."),
                TemplateItem(id: "164.308(a)(4)", title: "Information Access Management",
                             guidance: "Access to ePHI is granted based on role and reviewed."),
                TemplateItem(id: "164.308(a)(5)", title: "Security Awareness and Training",
                             guidance: "Staff are trained, and reminders, malware protection, login monitoring, and password practices are in place."),
                TemplateItem(id: "164.308(a)(6)", title: "Security Incident Procedures",
                             guidance: "Incidents are identified, responded to, and documented."),
                TemplateItem(id: "164.308(a)(7)", title: "Contingency Plan",
                             guidance: "Backups, disaster recovery, and emergency operation plans exist and are tested."),
                TemplateItem(id: "164.308(a)(8)", title: "Evaluation",
                             guidance: "Security is evaluated periodically and after major changes."),
                TemplateItem(id: "164.308(b)(1)", title: "Business Associate Contracts",
                             guidance: "Business associate agreements are in place with vendors that handle ePHI."),
            ]),
            TemplateGroup(name: "Physical Safeguards", items: [
                TemplateItem(id: "164.310(a)(1)", title: "Facility Access Controls",
                             guidance: "Physical access to systems with ePHI is limited, and there is a facility security plan and maintenance records."),
                TemplateItem(id: "164.310(b)", title: "Workstation Use",
                             guidance: "Rules define how workstations that access ePHI are used and where they are placed."),
                TemplateItem(id: "164.310(c)", title: "Workstation Security",
                             guidance: "Workstations that access ePHI are physically protected from unauthorized users."),
                TemplateItem(id: "164.310(d)(1)", title: "Device and Media Controls",
                             guidance: "Devices and media are tracked, wiped before reuse, and disposed of securely."),
            ]),
            TemplateGroup(name: "Technical Safeguards", items: [
                TemplateItem(id: "164.312(a)(1)", title: "Access Control",
                             guidance: "Unique user IDs, emergency access, automatic logoff, and encryption where reasonable."),
                TemplateItem(id: "164.312(b)", title: "Audit Controls",
                             guidance: "Activity in systems with ePHI is logged and reviewed."),
                TemplateItem(id: "164.312(c)(1)", title: "Integrity",
                             guidance: "ePHI is protected from improper changes or destruction."),
                TemplateItem(id: "164.312(d)", title: "Person or Entity Authentication",
                             guidance: "Users are verified before they access ePHI."),
                TemplateItem(id: "164.312(e)(1)", title: "Transmission Security",
                             guidance: "ePHI sent over networks is protected, including encryption where reasonable."),
            ]),
        ]
    )
}
