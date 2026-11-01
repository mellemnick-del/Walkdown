import Foundation

extension TemplateLibrary {
    /// A readiness checklist organized by the 12 principal PCI DSS requirements.
    /// Questions are Reassured's own wording, not the standard's text. PCI DSS is owned by the
    /// PCI Security Standards Council; use the official standard for a formal assessment.
    static let pciDSS = ChecklistTemplate(
        id: "pci-dss-readiness",
        name: "PCI DSS Readiness",
        area: .payments,
        summary: "Readiness questions organized by the 12 PCI DSS requirements, for anyone storing, processing, or sending card data.",
        source: "Organized by PCI DSS v4.0.1 requirements. Reassured's own wording.",
        groups: [
            TemplateGroup(name: "Secure Network and Systems", items: [
                TemplateItem("Req 1.a", "Network security controls protect the card data environment", "Firewall rules are documented, reviewed, and limit traffic into and out of the card data environment."),
                TemplateItem("Req 1.b", "Card data environment is segmented", "Systems that handle card data are separated from the rest of the network. Ask how segmentation is tested."),
                TemplateItem("Req 2.a", "Vendor default passwords are changed", "Default accounts and passwords on systems and devices are changed or disabled."),
                TemplateItem("Req 2.b", "Systems are securely configured", "Hardening standards are applied and only needed services run."),
            ]),
            TemplateGroup(name: "Protect Account Data", items: [
                TemplateItem("Req 3.a", "Card data storage is kept to a minimum", "Card data is only kept when there's a business need, and retention is defined."),
                TemplateItem("Req 3.b", "Sensitive authentication data isn't stored", "Full track data, CVV codes, and PINs aren't kept after authorization."),
                TemplateItem("Req 3.c", "Stored card numbers are unreadable", "Stored card numbers are encrypted, hashed, tokenized, or truncated, and keys are managed."),
                TemplateItem("Req 4.a", "Card data is encrypted in transit", "Card data sent over open networks uses strong encryption."),
                TemplateItem("Req 4.b", "Card numbers aren't sent by email or chat", "Card numbers aren't sent unprotected through messaging tools."),
            ]),
            TemplateGroup(name: "Vulnerability Management", items: [
                TemplateItem("Req 5.a", "Anti-malware is deployed and current", "Anti-malware runs on systems at risk and is kept up to date."),
                TemplateItem("Req 5.b", "Phishing protections are in place", "Controls detect and protect staff against phishing."),
                TemplateItem("Req 6.a", "Security patches are applied on time", "Critical patches are installed within a defined window."),
                TemplateItem("Req 6.b", "Software is developed securely", "Custom software follows secure coding, and public web apps are protected."),
                TemplateItem("Req 6.c", "Payment page scripts are managed", "Scripts on payment pages are authorized and monitored for changes."),
            ]),
            TemplateGroup(name: "Strong Access Control", items: [
                TemplateItem("Req 7.a", "Access to card data is need-to-know", "Access is limited by job role and reviewed."),
                TemplateItem("Req 8.a", "Every user has a unique ID", "No shared or generic accounts are used to access card data systems."),
                TemplateItem("Req 8.b", "MFA protects access to the card data environment", "MFA is required for access to the card data environment and all remote access."),
                TemplateItem("Req 8.c", "Password rules are enforced", "Password length, lockout, and change rules meet the standard."),
                TemplateItem("Req 9.a", "Physical access is restricted", "Entry to areas with card data systems is controlled and logged."),
                TemplateItem("Req 9.b", "Payment devices are protected from tampering", "Card readers and terminals are inventoried and inspected for skimmers."),
                TemplateItem("Req 9.c", "Media with card data is secured and destroyed", "Paper and electronic media is stored securely and destroyed when no longer needed."),
            ]),
            TemplateGroup(name: "Monitor and Test", items: [
                TemplateItem("Req 10.a", "Access to card data is logged", "Logs capture user activity on card data systems and are protected."),
                TemplateItem("Req 10.b", "Logs are reviewed", "Logs are reviewed daily, preferably with automated tools."),
                TemplateItem("Req 10.c", "Logs are kept long enough", "Logs are kept at least a year, with recent months immediately available."),
                TemplateItem("Req 11.a", "Vulnerability scans run quarterly", "Internal and external scans run regularly, and external scans use an approved vendor."),
                TemplateItem("Req 11.b", "Penetration testing is done", "Internal and external penetration tests run at least annually and after major changes."),
                TemplateItem("Req 11.c", "Wireless and change detection is in place", "Rogue wireless access points are detected, and critical file changes are monitored."),
            ]),
            TemplateGroup(name: "Security Policy and Program", items: [
                TemplateItem("Req 12.a", "Security policy is current", "A security policy exists, is reviewed annually, and is communicated."),
                TemplateItem("Req 12.b", "Scope is confirmed", "Card data flows and scope are documented and confirmed annually."),
                TemplateItem("Req 12.c", "Service providers are managed", "Providers that handle card data are listed, and responsibilities are written down."),
                TemplateItem("Req 12.d", "Staff are trained", "Security awareness training is completed at hire and annually."),
                TemplateItem("Req 12.e", "Incident response plan is ready", "An incident response plan covers card data compromise and is tested."),
            ]),
        ]
    )
}
