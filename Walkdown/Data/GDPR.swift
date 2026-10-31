import Foundation

extension TemplateLibrary {
    /// Key GDPR obligations with article references. Guidance is Walkdown's own wording.
    static let gdpr = ChecklistTemplate(
        id: "gdpr",
        name: "GDPR Essentials",
        area: .privacy,
        summary: "The core obligations of the EU General Data Protection Regulation for organizations handling EU personal data.",
        source: "Regulation (EU) 2016/679",
        groups: [
            TemplateGroup(name: "Lawful Processing", items: [
                TemplateItem("Art. 5", "Data protection principles are followed", "Data is collected for clear purposes, minimized, accurate, and not kept longer than needed."),
                TemplateItem("Art. 6", "Each processing activity has a lawful basis", "The basis (consent, contract, legal obligation, legitimate interest, and so on) is documented."),
                TemplateItem("Art. 7", "Consent is recorded and can be withdrawn", "Where consent is used, there's proof of it and an easy way to withdraw."),
                TemplateItem("Art. 9", "Special category data has extra protection", "Health, biometric, and other sensitive data has a valid condition for processing."),
            ]),
            TemplateGroup(name: "Individual Rights", items: [
                TemplateItem("Art. 13-14", "Privacy notices are provided", "People are told who's processing their data, why, and their rights."),
                TemplateItem("Art. 15-22", "Data subject requests are handled", "Access, correction, deletion, portability, and objection requests are answered within one month."),
            ]),
            TemplateGroup(name: "Accountability", items: [
                TemplateItem("Art. 24", "Responsibility is demonstrated", "Policies and records show how the organization complies."),
                TemplateItem("Art. 25", "Privacy by design and by default", "New systems are built to collect only what's needed."),
                TemplateItem("Art. 28", "Processors are under contract", "Data processing agreements are in place with vendors."),
                TemplateItem("Art. 30", "Records of processing are kept", "A register of processing activities exists and is current."),
                TemplateItem("Art. 35", "DPIAs are done for high-risk processing", "Data protection impact assessments are completed where required."),
                TemplateItem("Art. 37-39", "A DPO is appointed if required", "A data protection officer is named where the law requires one."),
            ]),
            TemplateGroup(name: "Security and Breaches", items: [
                TemplateItem("Art. 32", "Security is appropriate to the risk", "Encryption, access control, resilience, and regular testing are in place."),
                TemplateItem("Art. 33", "Breaches are reported to the authority within 72 hours", "There's a breach procedure with a 72-hour reporting path."),
                TemplateItem("Art. 34", "Affected people are told about high-risk breaches", "The procedure covers notifying individuals."),
            ]),
            TemplateGroup(name: "International Transfers", items: [
                TemplateItem("Art. 44-49", "Transfers outside the EU are protected", "Transfers rely on adequacy decisions, standard contractual clauses, or another valid mechanism."),
            ]),
        ]
    )
}
