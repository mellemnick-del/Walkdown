import Foundation

/// Plain-English background for each checklist. General guidance only, not legal advice.
struct FrameworkGuide {
    let whatItIs: String
    let whoNeedsIt: String
    let howAssessed: String
    let firstSteps: [String]
}

enum FrameworkGuides {
    static func guide(for templateID: String) -> FrameworkGuide? { all[templateID] }

    private static let all: [String: FrameworkGuide] = [
        "physical-walkdown": FrameworkGuide(
            whatItIs: "A hands-on check of the security you can see: doors, server rooms, desks, wireless gear, and how sensitive paper and devices are thrown away.",
            whoNeedsIt: "Every organization with an office, clinic, warehouse, or data closet. Most frameworks include physical security, so this supports all of them.",
            howAssessed: "Walk the site, watch how people actually behave, and photograph what you find.",
            firstSteps: [
                "Walk in the front door like a visitor and note what stops you.",
                "Ask for the list of people with server room access.",
                "Check desks and printers at the end of the day.",
            ]
        ),
        "itgc": FrameworkGuide(
            whatItIs: "IT General Controls are the basic controls over who can access systems, how changes are made, how systems are run, and how new systems are built.",
            whoNeedsIt: "Public companies (for SOX financial audits), organizations getting a financial statement audit, and anyone preparing for SOC 1 or SOC 2.",
            howAssessed: "Auditors pick samples, such as recent hires, departures, and changes, and check that each one followed the process.",
            firstSteps: [
                "Pull a list of everyone who left in the last 90 days and confirm their accounts are disabled.",
                "Find out who can push changes to production.",
                "Ask for the last user access review.",
            ]
        ),
        "nist-csf-2": FrameworkGuide(
            whatItIs: "A voluntary framework from NIST that organizes security into six functions: Govern, Identify, Protect, Detect, Respond, and Recover.",
            whoNeedsIt: "Any organization that wants a common, well-respected way to measure and improve its security program. It's often used as a starting point before stricter frameworks.",
            howAssessed: "Self-assessment or an outside review. There's no certification.",
            firstSteps: [
                "Decide who owns cybersecurity and who they report to.",
                "Build an inventory of your hardware, software, and data.",
                "Pick a target level for each category and measure the gap.",
            ]
        ),
        "cmmc-l1": FrameworkGuide(
            whatItIs: "The entry level of the Cybersecurity Maturity Model Certification, the Department of Defense program for protecting Federal Contract Information (FCI).",
            whoNeedsIt: "Defense contractors and subcontractors that handle FCI but not Controlled Unclassified Information (CUI).",
            howAssessed: "An annual self-assessment, with results entered in SPRS and affirmed by a senior company official.",
            firstSteps: [
                "Confirm which contracts include FCI and which systems touch it.",
                "Work through the 17 practices and record evidence for each.",
                "Get a SAM.gov and SPRS account set up for submitting results.",
            ]
        ),
        "cmmc-l2": FrameworkGuide(
            whatItIs: "CMMC Level 2 requires the 110 security requirements of NIST SP 800-171 to protect Controlled Unclassified Information (CUI).",
            whoNeedsIt: "Defense contractors and subcontractors that handle CUI. The contract states whether a self-assessment or a third-party assessment is required.",
            howAssessed: "Either a self-assessment or a certification assessment by an authorized third-party organization (C3PAO), typically every three years, with annual affirmations.",
            firstSteps: [
                "Define the CUI boundary: which people, systems, and locations handle it.",
                "Write or update the System Security Plan (SSP).",
                "Score yourself, and track every gap in a Plan of Action and Milestones (POA&M).",
            ]
        ),
        "nist-800-53-r5": FrameworkGuide(
            whatItIs: "NIST's full catalog of security and privacy controls, organized into 20 families.",
            whoNeedsIt: "Federal agencies and their systems (FISMA), cloud providers selling to government (FedRAMP), and state programs built on it.",
            howAssessed: "Controls are selected by system impact level (Low, Moderate, High), assessed by an independent assessor, and the system is authorized to operate.",
            firstSteps: [
                "Categorize the system as Low, Moderate, or High impact.",
                "Select the matching control baseline.",
                "Document how each control is implemented in the System Security Plan.",
            ]
        ),
        "hipaa-security": FrameworkGuide(
            whatItIs: "The HIPAA Security Rule sets administrative, physical, and technical safeguards for electronic protected health information (ePHI).",
            whoNeedsIt: "Healthcare providers, health plans, clearinghouses, and their business associates (vendors that handle ePHI).",
            howAssessed: "There's no official certification. Organizations must perform a risk analysis, and the HHS Office for Civil Rights investigates complaints and breaches.",
            firstSteps: [
                "Complete or update your security risk analysis.",
                "Name a security official.",
                "List every vendor that touches ePHI and confirm a business associate agreement is signed.",
            ]
        ),
        "pci-dss-readiness": FrameworkGuide(
            whatItIs: "The Payment Card Industry Data Security Standard protects cardholder data. It's set by the PCI Security Standards Council and enforced through the card brands and banks.",
            whoNeedsIt: "Any merchant or service provider that stores, processes, or transmits payment card data.",
            howAssessed: "Smaller merchants usually complete a Self-Assessment Questionnaire (SAQ). Larger ones need a Report on Compliance from a Qualified Security Assessor (QSA). Validation is annual.",
            firstSteps: [
                "Map where card data enters, moves, and is stored.",
                "Shrink scope: use a payment provider or tokenization so card data never touches your systems.",
                "Ask your bank (acquirer) which SAQ or report applies to you.",
            ]
        ),
        "soc2-readiness": FrameworkGuide(
            whatItIs: "SOC 2 is an attestation report on a service organization's controls, based on the AICPA's Trust Services Criteria.",
            whoNeedsIt: "SaaS companies, data centers, MSPs, and other service providers whose customers ask for proof of security.",
            howAssessed: "A licensed CPA firm issues the report. Type I covers controls at a point in time. Type II tests them over a period, usually 3 to 12 months.",
            firstSteps: [
                "Choose which categories are in scope. Security is always required.",
                "Write the core policies and assign owners.",
                "Run this readiness check, fix the gaps, then engage a CPA firm.",
            ]
        ),
        "gdpr": FrameworkGuide(
            whatItIs: "The EU General Data Protection Regulation governs how personal data of people in the EU is collected and used.",
            whoNeedsIt: "Organizations in the EU, and organizations elsewhere that offer goods or services to people in the EU or monitor their behavior.",
            howAssessed: "Supervisory authorities in each EU country enforce it. Serious violations can bring fines of up to 4% of global annual turnover or 20 million euros, whichever is higher.",
            firstSteps: [
                "Build a record of what personal data you process and why.",
                "Confirm a lawful basis for each processing activity.",
                "Set up a process to answer data subject requests within one month.",
            ]
        ),
    ]
}
