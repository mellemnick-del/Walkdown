import Foundation

extension TemplateLibrary {
    /// What cyber insurance carriers commonly ask about before they'll quote or renew coverage.
    /// Original Reassured checklist; every carrier's application is different, so this prepares
    /// a business for the common questions rather than replacing any carrier's form.
    static let cyberInsurance = ChecklistTemplate(
        id: "cyber-insurance",
        name: "Cyber Insurance Readiness",
        area: .insurance,
        summary: "The controls insurers ask about before quoting or renewing cyber coverage: MFA, EDR, backups, patching, email security, wire fraud, and incident response.",
        source: "Reassured original checklist, based on common carrier application questions",
        groups: [
            TemplateGroup(name: "Identity and Access", items: [
                TemplateItem("CI-1.1", "MFA on all email accounts", "Every mailbox, including webmail and Microsoft 365 or Google Workspace, requires MFA. Carriers ask about this on nearly every application."),
                TemplateItem("CI-1.2", "MFA on all remote access", "VPN, remote desktop gateways, and remote support tools require MFA for employees and vendors alike."),
                TemplateItem("CI-1.3", "MFA on admin accounts and cloud consoles", "Domain admins, server logins, firewall and backup consoles, and cloud admin portals require MFA."),
                TemplateItem("CI-1.4", "Separate, limited admin accounts", "Admins use separate privileged accounts, the list of admins is short, and it's reviewed at least yearly."),
                TemplateItem("CI-1.5", "Access removed promptly when people leave", "Accounts are disabled on the last day. Check two or three recent departures."),
                TemplateItem("CI-1.6", "No default or shared passwords", "Default passwords on devices are changed, and shared or service accounts have owners and strong passwords."),
            ]),
            TemplateGroup(name: "Endpoint and Email Protection", items: [
                TemplateItem("CI-2.1", "EDR on every endpoint and server", "Endpoint detection and response (not just antivirus) is installed everywhere and someone watches the alerts, in-house or through an MSP or MDR service."),
                TemplateItem("CI-2.2", "Email filtering for phishing and malware", "Inbound email is filtered, with attachment and link scanning."),
                TemplateItem("CI-2.3", "SPF, DKIM, and DMARC set up", "Email authentication records are in place, and DMARC is set to quarantine or reject."),
                TemplateItem("CI-2.4", "Risky content blocked", "Office macros from the internet are blocked, and external emails are tagged."),
                TemplateItem("CI-2.5", "Phishing training at least yearly", "Staff complete security awareness training and phishing simulations. Keep completion records; carriers often ask for them."),
            ]),
            TemplateGroup(name: "Backups and Recovery", items: [
                TemplateItem("CI-3.1", "Critical data backed up regularly", "Critical systems and data are backed up at least weekly, and daily for anything that changes often."),
                TemplateItem("CI-3.2", "A backup ransomware can't reach", "At least one copy is offline, immutable, or kept separate from the network and from normal domain credentials."),
                TemplateItem("CI-3.3", "Restores tested in the last year", "A real restore has been tested, and you know how long recovery takes."),
                TemplateItem("CI-3.4", "Backups protected", "Backups are encrypted, and the backup console requires MFA."),
                TemplateItem("CI-3.5", "Business continuity plan", "There's a plan for running the business if key systems are down for days."),
            ]),
            TemplateGroup(name: "Patching and Exposure", items: [
                TemplateItem("CI-4.1", "Critical patches applied quickly", "Critical security patches are applied within a set window, faster for internet-facing systems."),
                TemplateItem("CI-4.2", "No unsupported software", "No end-of-life operating systems or software, or any that remain are isolated and documented."),
                TemplateItem("CI-4.3", "Nothing risky exposed to the internet", "No remote desktop (RDP) or file sharing open to the internet. Carriers often scan for this themselves before quoting."),
                TemplateItem("CI-4.4", "External vulnerability scanning", "Internet-facing systems are scanned regularly, and findings are fixed."),
                TemplateItem("CI-4.5", "Asset inventory", "There's a current list of devices, servers, and cloud services."),
            ]),
            TemplateGroup(name: "Network and Monitoring", items: [
                TemplateItem("CI-5.1", "Critical systems segmented", "Servers, backups, and sensitive systems are on separate network segments from user devices."),
                TemplateItem("CI-5.2", "Firewalls deny by default", "Firewall rules allow only what's needed, and are reviewed."),
                TemplateItem("CI-5.3", "Logs kept and reviewed", "Security logs are collected centrally and kept at least 90 days."),
                TemplateItem("CI-5.4", "Alerts are watched around the clock", "Someone responds to security alerts 24/7, in-house or through a provider."),
            ]),
            TemplateGroup(name: "Incident Response", items: [
                TemplateItem("CI-6.1", "Written incident response plan", "A plan exists, names who does what, and has been tested with a tabletop exercise in the last year."),
                TemplateItem("CI-6.2", "Know who to call first", "The insurer's claim hotline, breach counsel, and forensics contacts are written down. Many policies require calling the insurer before hiring outside help."),
                TemplateItem("CI-6.3", "Ransomware playbook", "There are steps for isolating systems, preserving evidence, and restoring from backup."),
            ]),
            TemplateGroup(name: "Payments and Fraud", items: [
                TemplateItem("CI-7.1", "Verify payment changes by phone", "Changes to vendor or customer bank details are confirmed with a call to a known number, never one from the email."),
                TemplateItem("CI-7.2", "Dual approval for large payments", "Wires and large payments need a second person to approve."),
                TemplateItem("CI-7.3", "Staff trained on payment fraud", "Finance staff know the signs of business email compromise and fake invoices."),
            ]),
            TemplateGroup(name: "Data and Vendors", items: [
                TemplateItem("CI-8.1", "Know what sensitive data you hold", "You know what personal, health, or card data you store and roughly how many records. Applications ask for record counts."),
                TemplateItem("CI-8.2", "Sensitive data encrypted", "Sensitive data is encrypted at rest and in transit, and laptops use full-disk encryption."),
                TemplateItem("CI-8.3", "Old data deleted", "Data you no longer need is deleted on a schedule."),
                TemplateItem("CI-8.4", "Vendors with access are vetted", "Vendors with access to systems or sensitive data are reviewed, and contracts require security and breach notification."),
            ]),
            TemplateGroup(name: "Governance and History", items: [
                TemplateItem("CI-9.1", "Someone owns security", "A named person is responsible for security, even if an MSP does the work."),
                TemplateItem("CI-9.2", "Written security policies", "Core policies exist (acceptable use, access, backups, incident response) and staff acknowledge them."),
                TemplateItem("CI-9.3", "Past incidents documented", "Any incidents, claims, or breach notifications from the last 3 to 5 years are written down. Applications ask, and answers must be accurate."),
            ]),
        ],
        isReadinessLevel: true
    )
}
