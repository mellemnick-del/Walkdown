# Reassured: App Store Listing

Everything to paste into App Store Connect for version 1.0. Every field below has been checked against Apple's character limits.

## App Information

| Field | Value |
| --- | --- |
| **Name** (30 max) | `Reassured: Compliance Audits` (28) |
| **Subtitle** (30 max) | `CMMC, HIPAA & SOC 2 Readiness` (29) |
| **Primary category** | Business |
| **Secondary category** | Productivity |
| **Bundle ID** | com.nickmellem.reassured |
| **SKU** | REASSURED-IOS-001 |
| **Copyright** | 2026 Nick Mellem |
| **Content rights** | No. The app does not contain, show, or access third-party content. Checklist guidance is original wording; framework names and control IDs are public references. |

## Version 1.0

**Promotional text** (170 max, can be changed anytime without a new build), 155 characters:

```
Calm, private security audits and self-assessments. CMMC, HIPAA, SOC 2, PCI, NIST, and cyber insurance readiness built in. Everything stays on your device.
```

**Keywords** (100 max, commas, no spaces after commas; words already in the name and subtitle are left out because Apple already indexes them), 98 characters:

```
security,assessment,checklist,NIST,PCI,GDPR,cyber insurance,risk,evidence,ITGC,MSP,auditor,800-171
```

**What's New** (first version):

```
Reassured is here. Run security audits and self-assessments, turn every gap into a plan, keep evidence locked and ready, and export polished reports and certificates.
```

**Description** (4,000 max), 2411 characters:

```
Know where you stand. Know what to fix next.

Reassured is a calm, private way to run security audits and self-assessments on iPhone and iPad. Pick a framework, work through every control, capture evidence on the spot, and walk away with a clear score, a prioritized plan, and a report your clients will actually read.

Built for two kinds of people:
• Organizations getting ready for an assessment, a customer review, or cyber insurance renewal
• Assessors, auditors, and MSPs who run audits for clients in the field

FRAMEWORKS BUILT IN
• CMMC Level 1 and Level 2 (all 110 NIST SP 800-171 requirements)
• HIPAA Security Rule
• NIST Cybersecurity Framework 2.0 and NIST SP 800-53 families
• PCI DSS and SOC 2 readiness
• GDPR essentials
• Cyber Insurance Readiness
• IT General Controls and a physical security walkdown
Every checklist comes with a plain-English guide: what it is, who needs it, how it's assessed, and where to start.

AUDIT FASTER IN THE FIELD
• Walk Mode: one control at a time, with big Pass, Partial, Fail, and N/A buttons
• Swipe to answer, and search any control by ID or keyword
• Photo and document scanning, with markup that keeps the original untouched

TURN GAPS INTO A PLAN
• Every failed control becomes a prioritized task with an owner and due date
• Findings with severity, details, and recommendations
• Apple Intelligence can draft findings and executive summaries on your device

EVIDENCE, LOCKED AND READY
• Keep policies, reports, and screenshots in the Evidence Locker
• Reuse one document across every framework it supports
• Expiration reminders before evidence goes stale
• Lock the Locker with a PIN plus Face ID or Touch ID

REPORTS AND CERTIFICATES
• Polished PDF reports: cover page, score by area, findings, remediation plan, and evidence index
• A printable Certificate of Completion for finished audits
• Your logo and brand colors on reports

PRIVATE BY DESIGN
Everything stays on your device. No accounts, no servers, no tracking. Back up and restore with a single file you control.

Also: clients for assessors and MSPs, milestones that celebrate real progress, Home Screen and Lock Screen widgets, and a calm look that's easy on the eyes day or night.

Reassured helps you prepare for and organize assessments. Its reports and certificates record the work done; they are not a certification or attestation of compliance with any law, regulation, or standard.
```

## URLs

| Field | Value |
| --- | --- |
| **Support URL** (required) | To fill in once the website is live: `https://<your site>/support.html` |
| **Marketing URL** (optional) | `https://<your site>/` |
| **Privacy Policy URL** (required) | `https://<your site>/privacy.html` |

The pages are ready in the repo's `site/` folder.

## Screenshots

Upload in order 01 to 08 from `Design/appstore/screenshots/`:

| Display size | Folder | Pixel size |
| --- | --- | --- |
| iPhone 6.9" | `iphone/` | 1320 x 2868 |
| iPad 13" | `ipad/` | 2064 x 2752 |

Smaller iPhones and iPads use scaled versions of these automatically.

## App Privacy ("nutrition label")

Choose **Data Not Collected.**

Why that's accurate:
- No accounts, no servers, no analytics, no advertising, and no third-party SDKs
- Audits, photos, evidence, and settings are stored only on the device
- Backups and exported reports are files the user chooses to save or share
- "Get Help" opens the user's own Mail app; nothing is sent by Reassured itself
- Apple Intelligence writing help runs on device

If anything is ever added that sends data off the device (accounts, sync, crash reporting), these answers must be updated before that release.

## Age Rating

Answer **None / No** to every content question, including the questions about social features, user-generated content shared with others, messaging, advertising, gambling, and unrestricted web access. Expected rating: **4+**.

## Export Compliance

Already answered in the app: `ITSAppUsesNonExemptEncryption` is set to NO. Reassured only uses Apple's built-in encryption (iOS data protection, Keychain, and a hashed PIN), which is exempt. App Store Connect won't ask on each upload.

## App Review Information

| Field | Value |
| --- | --- |
| **Sign-in required** | No |
| **Contact** | Your name, phone, and email (only Apple sees these) |

**Notes for the reviewer** (838 characters):

```
No account or sign-in is needed. Everything is stored on the device.

To try the main flow:
1. Finish the short onboarding (choose either role).
2. Tap Self-Assess on Home, enter any organization name, and choose a checklist (for example CMMC Level 1).
3. Tap Start Walk Mode and answer a few controls. Mark one as Fail.
4. In the audit's ••• menu, tap Build Remediation Plan, then open Tasks.
5. In the audit's ••• menu, tap Mark Complete, then Certificate of Completion. Open Report to export the PDF.

Optional features: the camera is used to photograph and scan evidence. Face ID is used only if the user turns on the app lock or the Evidence Locker lock in Settings. Apple Intelligence writing help appears only on supported devices and runs on device.

Reports and certificates state that they are not a certification of compliance.
```

## Pricing

Still to decide. The price can be changed at any time after launch, and in-app purchases (for example, a Pro tier or white-label branding) can be added in a later version.
