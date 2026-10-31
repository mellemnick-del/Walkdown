# Accounts, Organizations, and MSP Support (Roadmap)

Status: **planned, not started.** Decisions below were made on 2026-10-31.

## Goal

People sign in with a password-protected account, create users in their organization, and (for MSPs and consultancies) manage multiple client organizations underneath their own.

## Decisions

| Topic | Decision |
| --- | --- |
| Backend | **Not chosen yet.** Options reviewed: Supabase (recommended: Postgres, auth, row-level security, SOC 2 report, HIPAA BAA on higher plans), Firebase, Apple CloudKit. |
| Evidence files | **Stay on the device that captured them.** Only metadata (title, type, topics, expiration, linked controls) syncs. Avoids holding CUI (CMMC) or ePHI (HIPAA) on our servers. |
| Roles | **Owner, Admin, Assessor, Viewer.** |

### Roles

| Role | Can do |
| --- | --- |
| Owner | Everything, including billing and deleting the organization. |
| Admin | Manage users, roles, and client organizations. Everything an Assessor can do. |
| Assessor | Create and edit audits, findings, tasks, and evidence metadata. |
| Viewer | Read-only. Good for clients reviewing their own results. |

### Organization structure

```
Provider organization (MSP, consultancy, or a single company)
  Users with roles
  Client organizations (optional, for MSPs and assessors)
    Audits, findings, tasks, evidence metadata
    Optional client users (usually Viewer)
```

A user can belong to more than one organization and switch between them.

## Already built (local, ready to sync later)

- **Clients**: on-device client organizations that group audits, tasks, and evidence. These map directly to client organizations once accounts exist.
- **App lock**: Face ID or device passcode.

## Requirements to remember

- **Apple account deletion**: apps that let people create accounts must let them delete the account in the app (App Review Guideline 5.1.1(v)).
- **Sign in with Apple**: required if we offer Google or other third-party sign-in (Guideline 4.8).
- **Our own compliance**: once we host customer data, customers will ask for our SOC 2 report, a security page, and a data processing agreement.
- **MFA** for accounts, especially Owners and Admins.
- **Tenant isolation**: every table scoped to an organization with row-level security, and tests proving one organization can't read another's data.
- **Audit trail**: log who changed which result, finding, or task.

## Rough phases

1. Accounts: sign up, sign in, MFA, password reset, account deletion.
2. Organizations and roles: create org, invite users, assign roles, switch orgs.
3. Client organizations for MSPs: create clients, assign team members, client Viewer access.
4. Sync: audits, controls, findings, tasks, and evidence metadata, with conflict handling.
5. Web dashboard (optional) for admins and clients.
