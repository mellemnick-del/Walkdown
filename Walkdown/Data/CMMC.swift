import Foundation

// CMMC Level 2 assesses the 110 security requirements of NIST SP 800-171 Rev 2.
// Level 1 covers the basic safeguarding requirements of FAR 52.204-21, shown here with their
// matching 800-171 numbers. NIST publications are US government works. Titles and guidance are
// Walkdown's own short wording; check the official requirement text during an assessment.

private enum NIST171 {
    static let accessControl = TemplateGroup(name: "Access Control (AC)", items: [
        TemplateItem("AC 3.1.1", "Limit access to authorized users, processes, and devices", "Account list matches current staff and approved devices. Ask for the account provisioning process."),
        TemplateItem("AC 3.1.2", "Limit users to the transactions and functions they're allowed", "Roles or groups restrict what each user can do. Spot-check a few user permissions."),
        TemplateItem("AC 3.1.3", "Control the flow of CUI", "Firewalls, DLP, or rules keep CUI from moving to unapproved places."),
        TemplateItem("AC 3.1.4", "Separate duties", "No single person can perform and approve sensitive actions alone."),
        TemplateItem("AC 3.1.5", "Least privilege", "Admin rights are limited to those who need them. Review the admin group membership."),
        TemplateItem("AC 3.1.6", "Use non-privileged accounts for everyday work", "Admins have separate accounts for email and browsing."),
        TemplateItem("AC 3.1.7", "Block non-privileged users from privileged functions, and log it", "Standard users can't run admin tools, and attempts are logged."),
        TemplateItem("AC 3.1.8", "Limit failed logon attempts", "Account lockout policy is configured. Check the threshold."),
        TemplateItem("AC 3.1.9", "Show privacy and security notices", "A logon banner appears and matches CUI requirements."),
        TemplateItem("AC 3.1.10", "Session lock with hidden screen content", "Screens lock after inactivity and hide what was displayed."),
        TemplateItem("AC 3.1.11", "End sessions automatically", "Sessions terminate after a defined condition, such as timeout."),
        TemplateItem("AC 3.1.12", "Monitor and control remote access", "Remote access (VPN, RDP) is approved, logged, and reviewed."),
        TemplateItem("AC 3.1.13", "Encrypt remote access sessions", "Remote sessions use strong encryption."),
        TemplateItem("AC 3.1.14", "Route remote access through managed points", "All remote access goes through approved gateways."),
        TemplateItem("AC 3.1.15", "Authorize remote privileged commands", "Remote admin access is specifically approved and limited."),
        TemplateItem("AC 3.1.16", "Authorize wireless access before connecting", "Wireless networks are approved and documented."),
        TemplateItem("AC 3.1.17", "Protect wireless with authentication and encryption", "Wi-Fi uses WPA2 or WPA3 Enterprise or equivalent."),
        TemplateItem("AC 3.1.18", "Control mobile device connections", "Mobile devices are managed (MDM) before accessing company systems."),
        TemplateItem("AC 3.1.19", "Encrypt CUI on mobile devices", "Laptops and phones that hold CUI are encrypted."),
        TemplateItem("AC 3.1.20", "Control connections to external systems", "Use of personal and third-party systems is limited and approved."),
        TemplateItem("AC 3.1.21", "Limit portable storage on external systems", "Company USB drives aren't used on outside systems without approval."),
        TemplateItem("AC 3.1.22", "Control CUI on public systems", "Nothing sensitive is posted to public websites. Ask who reviews public content."),
    ])

    static let awareness = TemplateGroup(name: "Awareness and Training (AT)", items: [
        TemplateItem("AT 3.2.1", "Security awareness for all users", "Everyone gets security awareness training. Ask for completion records."),
        TemplateItem("AT 3.2.2", "Role-based training", "Admins and security staff get training for their duties."),
        TemplateItem("AT 3.2.3", "Insider threat awareness", "Training covers how to recognize and report insider threats."),
    ])

    static let audit = TemplateGroup(name: "Audit and Accountability (AU)", items: [
        TemplateItem("AU 3.3.1", "Create and keep audit logs", "Logs are generated and retained long enough to investigate incidents."),
        TemplateItem("AU 3.3.2", "Trace actions to individual users", "Logs show who did what. No shared accounts."),
        TemplateItem("AU 3.3.3", "Review and update logged events", "The list of logged events is reviewed periodically."),
        TemplateItem("AU 3.3.4", "Alert when logging fails", "Someone is notified if logging stops."),
        TemplateItem("AU 3.3.5", "Correlate log review and reporting", "Logs from multiple systems are brought together (SIEM or similar)."),
        TemplateItem("AU 3.3.6", "Log reduction and reporting", "Tools can filter logs and generate reports on demand."),
        TemplateItem("AU 3.3.7", "Sync clocks to a trusted time source", "Systems use NTP from an authoritative source."),
        TemplateItem("AU 3.3.8", "Protect logs and logging tools", "Logs can't be altered or deleted by regular users."),
        TemplateItem("AU 3.3.9", "Limit who manages logging", "Only a small set of privileged users can change logging."),
    ])

    static let config = TemplateGroup(name: "Configuration Management (CM)", items: [
        TemplateItem("CM 3.4.1", "Baselines and inventories", "There's a current hardware and software inventory and baseline configurations."),
        TemplateItem("CM 3.4.2", "Enforce security settings", "Hardening standards (for example, CIS or STIG based) are applied."),
        TemplateItem("CM 3.4.3", "Track and approve changes", "Changes go through a documented approval process."),
        TemplateItem("CM 3.4.4", "Analyze security impact of changes", "Changes are reviewed for security impact before they're made."),
        TemplateItem("CM 3.4.5", "Restrict who can make changes", "Only authorized people can change systems."),
        TemplateItem("CM 3.4.6", "Least functionality", "Systems only run what they need."),
        TemplateItem("CM 3.4.7", "Restrict unneeded programs, ports, and services", "Unneeded ports and services are disabled."),
        TemplateItem("CM 3.4.8", "Allowlist or blocklist software", "An application control policy is in place."),
        TemplateItem("CM 3.4.9", "Control user-installed software", "Users can't install software freely, and installs are monitored."),
    ])

    static let identity = TemplateGroup(name: "Identification and Authentication (IA)", items: [
        TemplateItem("IA 3.5.1", "Identify users, processes, and devices", "Every user and device has a unique identifier."),
        TemplateItem("IA 3.5.2", "Authenticate before access", "Users and devices are verified before access is granted."),
        TemplateItem("IA 3.5.3", "Multifactor authentication", "MFA for privileged accounts and for network access to all accounts."),
        TemplateItem("IA 3.5.4", "Replay-resistant authentication", "Network logons use protocols that resist replay attacks."),
        TemplateItem("IA 3.5.5", "Don't reuse identifiers", "Old usernames aren't reassigned for a defined period."),
        TemplateItem("IA 3.5.6", "Disable inactive identifiers", "Unused accounts are disabled after a set time."),
        TemplateItem("IA 3.5.7", "Password complexity", "Minimum complexity and change of characters is enforced."),
        TemplateItem("IA 3.5.8", "No password reuse", "Password history prevents reuse for a set number of generations."),
        TemplateItem("IA 3.5.9", "Temporary passwords change immediately", "First logon with a temporary password forces a change."),
        TemplateItem("IA 3.5.10", "Store and send passwords protected", "Passwords are only stored and transmitted encrypted or hashed."),
        TemplateItem("IA 3.5.11", "Hide password feedback", "Password fields mask what's typed."),
    ])

    static let incident = TemplateGroup(name: "Incident Response (IR)", items: [
        TemplateItem("IR 3.6.1", "Incident handling capability", "An incident response plan covers preparation, detection, containment, recovery, and follow-up."),
        TemplateItem("IR 3.6.2", "Track, document, and report incidents", "Incidents are logged and reported to the right people, including DoD where required."),
        TemplateItem("IR 3.6.3", "Test incident response", "The plan is tested, for example with a tabletop exercise."),
    ])

    static let maintenance = TemplateGroup(name: "Maintenance (MA)", items: [
        TemplateItem("MA 3.7.1", "Perform system maintenance", "Maintenance is scheduled and recorded."),
        TemplateItem("MA 3.7.2", "Control maintenance tools and people", "Maintenance tools and personnel are approved."),
        TemplateItem("MA 3.7.3", "Sanitize equipment sent offsite", "CUI is removed from equipment before offsite repair."),
        TemplateItem("MA 3.7.4", "Scan diagnostic media", "Media with diagnostic tools is checked for malware first."),
        TemplateItem("MA 3.7.5", "MFA for remote maintenance", "Remote maintenance uses MFA, and sessions end when done."),
        TemplateItem("MA 3.7.6", "Supervise outside maintenance staff", "Vendors without access authorization are escorted."),
    ])

    static let media = TemplateGroup(name: "Media Protection (MP)", items: [
        TemplateItem("MP 3.8.1", "Protect media with CUI", "Paper and digital media with CUI are stored securely."),
        TemplateItem("MP 3.8.2", "Limit access to CUI on media", "Only authorized people can get to CUI media."),
        TemplateItem("MP 3.8.3", "Sanitize or destroy media", "Media is wiped or destroyed before disposal or reuse. Ask for records."),
        TemplateItem("MP 3.8.4", "Mark media with CUI markings", "Media containing CUI is labeled."),
        TemplateItem("MP 3.8.5", "Control media during transport", "Media leaving the site is tracked."),
        TemplateItem("MP 3.8.6", "Encrypt media in transport", "Digital media carried offsite is encrypted."),
        TemplateItem("MP 3.8.7", "Control removable media", "USB and removable media use is restricted."),
        TemplateItem("MP 3.8.8", "No ownerless portable storage", "Unknown or unowned USB drives aren't allowed."),
        TemplateItem("MP 3.8.9", "Protect backups", "Backups containing CUI are protected where they're stored."),
    ])

    static let personnel = TemplateGroup(name: "Personnel Security (PS)", items: [
        TemplateItem("PS 3.9.1", "Screen people before access", "Background checks happen before access to CUI."),
        TemplateItem("PS 3.9.2", "Protect systems when people leave or move", "Access is removed promptly on termination or transfer. Check a recent example."),
    ])

    static let physical = TemplateGroup(name: "Physical Protection (PE)", items: [
        TemplateItem("PE 3.10.1", "Limit physical access", "Only authorized people can enter areas with systems and CUI."),
        TemplateItem("PE 3.10.2", "Protect and monitor the facility", "The facility and its support systems are protected and monitored."),
        TemplateItem("PE 3.10.3", "Escort and monitor visitors", "Visitors are escorted and their activity is monitored."),
        TemplateItem("PE 3.10.4", "Log physical access", "Physical access logs are kept."),
        TemplateItem("PE 3.10.5", "Manage physical access devices", "Keys, badges, and combinations are controlled and changed when needed."),
        TemplateItem("PE 3.10.6", "Safeguard alternate work sites", "Remote and home work sites have protections for CUI."),
    ])

    static let risk = TemplateGroup(name: "Risk Assessment (RA)", items: [
        TemplateItem("RA 3.11.1", "Assess risk periodically", "A risk assessment has been done recently."),
        TemplateItem("RA 3.11.2", "Scan for vulnerabilities", "Vulnerability scans run regularly and when new threats appear."),
        TemplateItem("RA 3.11.3", "Fix vulnerabilities by risk", "Scan results are remediated based on severity."),
    ])

    static let assessment = TemplateGroup(name: "Security Assessment (CA)", items: [
        TemplateItem("CA 3.12.1", "Assess controls periodically", "Security controls are reviewed for effectiveness."),
        TemplateItem("CA 3.12.2", "Plans of action", "A POA&M tracks gaps and how they'll be fixed."),
        TemplateItem("CA 3.12.3", "Monitor controls continuously", "Controls are monitored on an ongoing basis."),
        TemplateItem("CA 3.12.4", "System security plan", "A current SSP describes the boundary, environment, and how each requirement is met."),
    ])

    static let systemComms = TemplateGroup(name: "System and Communications Protection (SC)", items: [
        TemplateItem("SC 3.13.1", "Protect network boundaries", "Firewalls monitor and control traffic at external and key internal boundaries."),
        TemplateItem("SC 3.13.2", "Secure architecture and engineering", "Security is built into designs and development."),
        TemplateItem("SC 3.13.3", "Separate user and admin functions", "Management interfaces are separated from user functions."),
        TemplateItem("SC 3.13.4", "No leaks through shared resources", "Shared system resources don't expose data between users."),
        TemplateItem("SC 3.13.5", "Separate public-facing systems", "Public systems sit in a DMZ or separate subnet."),
        TemplateItem("SC 3.13.6", "Deny network traffic by default", "Firewall rules deny everything not explicitly allowed."),
        TemplateItem("SC 3.13.7", "Prevent split tunneling", "Remote devices can't connect to the internet and VPN at the same time."),
        TemplateItem("SC 3.13.8", "Encrypt CUI in transit", "CUI is encrypted when sent unless otherwise protected."),
        TemplateItem("SC 3.13.9", "End idle network connections", "Connections close at end of session or after inactivity."),
        TemplateItem("SC 3.13.10", "Manage encryption keys", "Keys are created, stored, and rotated securely."),
        TemplateItem("SC 3.13.11", "FIPS-validated encryption", "Encryption protecting CUI uses FIPS-validated modules."),
        TemplateItem("SC 3.13.12", "Control collaborative devices", "Cameras and mics can't be turned on remotely, and users can tell when they're on."),
        TemplateItem("SC 3.13.13", "Control mobile code", "Scripts and active content are controlled."),
        TemplateItem("SC 3.13.14", "Control VoIP", "VoIP systems are managed and monitored."),
        TemplateItem("SC 3.13.15", "Protect session authenticity", "Sessions are protected against hijacking (for example, TLS)."),
        TemplateItem("SC 3.13.16", "Protect CUI at rest", "Stored CUI is encrypted or otherwise protected."),
    ])

    static let integrity = TemplateGroup(name: "System and Information Integrity (SI)", items: [
        TemplateItem("SI 3.14.1", "Fix flaws on time", "Patches are applied on a defined schedule. Check patch reports."),
        TemplateItem("SI 3.14.2", "Malware protection", "Antivirus or EDR runs on all systems."),
        TemplateItem("SI 3.14.3", "Monitor security alerts", "Someone follows advisories (for example, CISA) and acts on them."),
        TemplateItem("SI 3.14.4", "Keep malware protection updated", "Definitions and agents update automatically."),
        TemplateItem("SI 3.14.5", "Scan systems and files", "Periodic scans run, and outside files are scanned when opened."),
        TemplateItem("SI 3.14.6", "Monitor for attacks", "Inbound and outbound traffic is monitored for signs of attack."),
        TemplateItem("SI 3.14.7", "Detect unauthorized use", "Unauthorized use of systems is detected."),
    ])

    static let all = [accessControl, awareness, audit, config, identity, incident, maintenance,
                      media, personnel, physical, risk, assessment, systemComms, integrity]

    /// The 800-171 numbers that make up CMMC Level 1.
    static let level1IDs: Set<String> = [
        "AC 3.1.1", "AC 3.1.2", "AC 3.1.20", "AC 3.1.22",
        "IA 3.5.1", "IA 3.5.2",
        "MP 3.8.3",
        "PE 3.10.1", "PE 3.10.3", "PE 3.10.4", "PE 3.10.5",
        "SC 3.13.1", "SC 3.13.5",
        "SI 3.14.1", "SI 3.14.2", "SI 3.14.4", "SI 3.14.5",
    ]
}

extension TemplateLibrary {
    static let cmmcLevel1 = ChecklistTemplate(
        id: "cmmc-l1",
        name: "CMMC Level 1",
        area: .defense,
        summary: "Basic safeguarding for Federal Contract Information (FCI), shown with NIST 800-171 numbering.",
        source: "CMMC Level 1 (FAR 52.204-21), mapped to NIST SP 800-171 Rev 2",
        groups: NIST171.all.compactMap { group in
            let items = group.items.filter { NIST171.level1IDs.contains($0.id) }
            return items.isEmpty ? nil : TemplateGroup(name: group.name, items: items)
        }
    )

    static let cmmcLevel2 = ChecklistTemplate(
        id: "cmmc-l2",
        name: "CMMC Level 2 / NIST 800-171",
        area: .defense,
        summary: "All 110 NIST SP 800-171 Rev 2 requirements for protecting Controlled Unclassified Information (CUI).",
        source: "CMMC Level 2, NIST SP 800-171 Rev 2",
        groups: NIST171.all
    )
}
