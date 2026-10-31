# Walkdown (working title)

**Walk the site. Leave with the report.**

An offline field audit companion for security auditors on iPhone and iPad. Pick a checklist, work through each control on site, capture photo and document evidence, write up findings, and export a clean PDF report. Everything stays on the device.

## What's in v1

| Screen | What it does |
| --- | --- |
| **Audits** | Your audits with a progress ring, how many controls are done, and failures. Filter by In Progress, Complete, or Archived. Swipe to archive or delete. |
| **New Audit** | Client, site, location, auditor, date, scope notes, and the checklist to use. |
| **Workspace** | Controls grouped by area, a progress bar, counts per result, and a live score. Filter to "Not Started" or "Fail and Partial". |
| **Control Detail** | Plain-English guidance, four big result buttons (Pass, Partial, Fail, N/A), notes with dictation, evidence from the camera, document scanner, or photo library, and linked findings. |
| **Findings** | Every finding sorted by severity (Critical, High, Medium, Low) with details and a recommendation. Creating one from a control pre-fills it from your notes. |
| **Report** | A PDF with a cover page, executive summary, score by area, findings with evidence photos, and every control result. Share with AirDrop, Mail, or Files. |
| **Settings** | Your name and company for reports, plus an optional Face ID lock. |

### Built-in checklists

| Checklist | Controls | Source and licensing |
| --- | --- | --- |
| Physical Security Walkdown | 23 | Written for Walkdown. |
| NIST CSF 2.0 (Categories) | 22 | NIST Cybersecurity Framework 2.0, a US government work. Category IDs and names are NIST's; guidance text is Walkdown's own. |
| HIPAA Security Rule | 18 | 45 CFR 164.308, 164.310, 164.312 (federal regulation). Guidance text is Walkdown's own. |

Not included on purpose: **CIS Controls** (licensed for non-commercial use with no derivatives) and **PCI DSS** (copyrighted by the PCI Security Standards Council). Add them only with permission.

### Scoring

Pass counts as 1, Partial as 0.5, Fail as 0. N/A and Not Started are left out. The score is shown per audit and per area.

### Privacy

- No accounts, no servers, no analytics. Data is stored with SwiftData on the device.
- Photos are resized to 2000 px and saved as JPEG to keep audits small.
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
  Models/     SwiftData models: Audit, ControlResult, Evidence, Finding
  Data/       Built-in checklist templates
  Services/   Audit creation, image handling, PDF report, Face ID lock
  Views/      Audits, Workspace, Findings, Report, Settings
  Resources/  Assets and privacy manifest
```

## Roadmap

- Custom checklist builder (create your own or copy a built-in one)
- Company logo on the report cover
- Full NIST CSF 2.0 subcategories (106 controls)
- Finding templates and a remediation tracker
- Compare a client's audits year over year
- iCloud sync and team audits
- App icon
