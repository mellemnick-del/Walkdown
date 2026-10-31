# Walkdown (working title)

**Know where you stand. Know what to fix next.**

A compliance and audit app for iPhone and iPad, built for two kinds of people:

- **Organizations** that want to get compliant: self-assess, see a score, and work a remediation plan.
- **Assessors and auditors** who go on site: run the audit, capture evidence, and hand over a clean report.

Everything stays on the device.

## First launch

A short welcome explains the app, then asks who it's for: **My Organization** or **I'm an Assessor**. The choice sets the default audit type (self-assessment or on-site) and the wording on Home. Every feature is available either way, and it can be changed in Settings.

## App structure

| Tab | What it does |
| --- | --- |
| **Home** | Greeting, a score ring for your most active audit, open and overdue task counts, the next three tasks to work, other audits in progress, and quick actions (New Audit, Checklists, Get Help). |
| **Audits** | All audits and self-assessments. |
| **Tasks** | Remediation tasks grouped into Overdue, Due This Week, Later, and No Due Date. Swipe to complete. |
| **Locker** | The Evidence Locker: policies, reports, screenshots, certificates, and scans, sorted into Expired, Expiring Soon, and Current. |
| **Library** | Every checklist grouped by audit area and searchable. Each one opens to a plain-English guide (what it is, who needs it, how it's assessed, first steps), Self-Assess and On-Site Audit buttons, and every control. |

### Clients (for assessors and MSPs)

- Audits tab > Clients: add the organizations you audit or manage, with industry, contact, and notes.
- Each client shows its latest score, audits, open tasks, and evidence, with a "New Audit for" shortcut.
- New audits and evidence can be assigned to a client. When attaching evidence to a control, only that client's evidence is offered, so one client's documents never appear in another client's audit.
- Clients map to synced client organizations once accounts are added. See [docs/ACCOUNTS_PLAN.md](docs/ACCOUNTS_PLAN.md).

### Remediation

- **Build Remediation Plan** (in an audit's menu) turns every Fail or Partial control into a task. Priority comes from the worst linked finding, or Fail = High and Partial = Medium.
- Suggested due dates: Critical 7 days, High 30, Medium 60, Low 90.
- Each task has an owner, due date, status, and "how to fix it" notes pre-filled from the control guidance and audit notes.
- Closing a task offers to mark its control as Pass, so the score climbs as gaps get fixed. It never changes the result on its own.

### Evidence Locker

- Import files (PDF, images, documents, spreadsheets), scan paper documents into a single PDF, or add photos and screenshots.
- Each item has a type, topics, notes, and an optional expiration date. Reminders fire 30 days and 7 days before, and on the day it expires.
- Link one item to controls in any audit. Topics (MFA, Encryption, Backups, and so on) suggest matching evidence on each control, so one document supports CMMC, SOC 2, HIPAA, and more.
- Preview with Quick Look and share from the app.
- Reports list "Evidence on file" under each control and add an Evidence Index appendix.

### Branding (white-label foundation)

Settings > Branding sets a company name, logo, and brand color. The color tints the whole app and report headings, and the logo goes on report covers. This is the base for paid white-label plans: one App Store app that an organization brands from inside, which fits Apple's rules on template apps (guideline 4.2.6). Pricing and how branding gets unlocked are still to be decided.

### Reminders

Local notifications at 9 AM for evidence expiration and task due dates. Nothing is sent to a server.

### Get Help

"Talk to an expert" is available from Home, any audit, and any control. Requests go to the contact email set in Settings, with the topic filled in. Official resources (CISA, NIST, CMMC, HHS, PCI SSC) are always listed.

## Audit screens

| Screen | What it does |
| --- | --- |
| **Audits** | Your audits with a progress ring, how many controls are done, and failures. Filter by In Progress, Complete, or Archived. Swipe to archive or delete. |
| **New Audit** | Client, site, location, auditor, date, scope notes, and the checklist to use. |
| **Workspace** | Controls grouped by area, a progress bar, counts per result, and a live score. Filter to "Not Started" or "Fail and Partial". |
| **Control Detail** | Plain-English guidance, four big result buttons (Pass, Partial, Fail, N/A), notes with dictation, evidence from the camera, document scanner, or photo library, and linked findings. |
| **Findings** | Every finding sorted by severity (Critical, High, Medium, Low) with details and a recommendation. Creating one from a control pre-fills it from your notes. |
| **Report** | A PDF with a cover page, executive summary, score by area, findings with evidence photos, and every control result. Share with AirDrop, Mail, or Files. |
| **Settings** | Your name and company for reports, plus an optional Face ID lock. |

### Audit types

- **On-Site Audit:** walk a client site and record what you see.
- **Self-Assessment:** answer a checklist for your own organization or a client's. No site fields, and the report is titled "Security Self-Assessment".

### Checklist library

Checklists are grouped by audit area and searchable. Browse them from New Audit or Settings.

| Area | Checklist | Controls | Source and licensing |
| --- | --- | --- | --- |
| General and IT Controls | Physical Security Walkdown | 23 | Walkdown original |
| General and IT Controls | IT General Controls | 17 | Walkdown original |
| General and IT Controls | NIST CSF 2.0 (Categories) | 22 | NIST, US government work |
| Defense Contractors | CMMC Level 1 | 17 | FAR 52.204-21, shown with NIST 800-171 Rev 2 numbering |
| Defense Contractors | CMMC Level 2 / NIST 800-171 | 110 | NIST SP 800-171 Rev 2, US government work |
| Federal Systems | NIST 800-53 Rev 5 (Families) | 20 | NIST, US government work |
| Healthcare | HIPAA Security Rule | 18 | 45 CFR 164.308, 164.310, 164.312 |
| Payments | PCI DSS Readiness | 32 | Organized by the 12 PCI DSS v4.0.1 requirements, Walkdown's own wording |
| Service Organizations | SOC 2 Readiness | 39 | Organized by the Trust Services Criteria categories, Walkdown's own wording |
| Privacy | GDPR Essentials | 16 | Regulation (EU) 2016/679 |

Guidance text in every checklist is Walkdown's own wording. Official names and IDs are used for reference only.

**PCI DSS and SOC 2:** the standards are owned by the PCI Security Standards Council and the AICPA. Walkdown's checklists follow their structure with original questions, never the standards' text, and don't imply endorsement. Get a legal review before selling the app.

**Not included:** ISO 27001, HITRUST, and CIS Controls (licensed content).

**Coming next:** CJIS Security Policy (law enforcement) and IRS Publication 1075 (Federal Tax Information). These will be built from the current official documents, not from memory.

### Scoring

Pass counts as 1, Partial as 0.5, Fail as 0. N/A and Not Started are left out. The score is shown per audit and per area.

### Privacy

- No accounts, no servers, no analytics. Data is stored with SwiftData on the device.
- Photos are resized to 2000 px and saved as JPEG to keep audits small.
- Data protection is set to Complete, so stored files are encrypted and unreadable while the device is locked.
- Reports are built on the device and only leave it when you share them.

## Building

Requires Xcode 15 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate
open Walkdown.xcodeproj
```

Set your team under Signing & Capabilities. The bundle ID is `com.nickmellem.walkdown` and can be changed in `project.yml` before the first upload.

## Project layout

```
Walkdown/
  App/        App entry and settings keys
  Models/     SwiftData models: Audit, ControlResult, Evidence, Finding, RemediationTask, LockerItem, Client
  Data/       Built-in checklist templates
  Services/   Audit creation, image handling, PDF report, Face ID lock
  Views/      Home, Audits, Workspace, Findings, Tasks, Library, Help, Report, Settings
  Resources/  Assets and privacy manifest
```

## Roadmap

- Accounts, organizations, roles, and MSP client management with cloud sync. Decisions so far are in [docs/ACCOUNTS_PLAN.md](docs/ACCOUNTS_PLAN.md).
- Paid plans: unlock branding for organizations (StoreKit subscriptions)

- CJIS Security Policy and IRS Publication 1075 checklists
- Custom checklist builder (create your own or copy a built-in one)
- Full NIST 800-53 controls and state frameworks (for example, TX-RAMP)
- Company logo on the report cover
- Full NIST CSF 2.0 subcategories (106 controls)
- Finding templates and a remediation tracker
- Compare a client's audits year over year
- iCloud sync and team audits

