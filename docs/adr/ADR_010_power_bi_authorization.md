# ADR-010: Power BI Authorization Model: Entra ID SSO, External OAuth, Per-User UPN Mapping

**Status:** Proposed (drafted from the ADR Review working document; decision pending the Jeremy/Diana review session)
**Category:** Access
**Date:** August 5, 2026
**Deciders:** Jeremy Myers (VP AI & Analytics)
**Consulted:** Kenny Yeung (IT — provisioning); Diana (Data & AI Team)
**Related:** ADR-004 (No Logic in Power BI), ADR-006 (Change Management — Gate 4 access governance), ADR-001 (Stack Selection)

> **Source note.** Drafted from the ADR Review working document (Part 2, ADR-010); decision box empty, recommended option drafted pending the session. The three-layer auth chain described here was established during the POC; confirm the provisioning runbook steps with Kenny Yeung before ratification [confirm].

## Context

The Power BI to Snowflake connection uses a three-layer auth chain established during the POC: Power BI tenant SSO via Entra ID, Snowflake external OAuth configured against the Entra ID tenant, and per-user UPN mapping so each staff member's Power BI session connects to Snowflake as their individual Snowflake user. Per-user identity is what enables row-level security in Snowflake rather than in Power BI, consistent with ADR-004's rule that no security logic lives in the display layer.

Without an ADR documenting this pattern, Kenny cannot provision new users consistently and every new report connection becomes a custom engagement. Gate 4 of the change process (access governance, ADR-006) also needs a documented standard to enforce.

## Decision

The **three-layer pattern is the standard** for all Power BI connectivity to Snowflake:

1. **Power BI tenant SSO via Entra ID** — staff authenticate with their NS11MM identity.
2. **Snowflake external OAuth against the Entra ID tenant** — no separate Snowflake passwords.
3. **Per-user UPN mapping** — each session reaches Snowflake as the individual's Snowflake user.

**Row-level security lives in Snowflake**, never as Power BI DAX (ADR-004). Per-user identity also preserves the individual audit trail in Snowflake query history.

**IT provisioning runbook** (owned by Kenny Yeung, maintained inside this ADR): create a Snowflake user with the staff member's UPN; grant the appropriate functional role; add the user to the Power BI workspace. [confirm exact role-grant steps and workspace list]

## Options considered

### Option A: Three-layer pattern, RLS in Snowflake (recommended)

Wins because it is already proven in the POC, enforces ADR-004 structurally (Power BI physically cannot see rows Snowflake withholds), keeps a per-user audit trail, and reduces provisioning to a repeatable runbook enforced at Gate 4.

### Option B: Shared service account (set aside)

Its genuine advantage: simplest provisioning — one credential, no per-user Snowflake accounts, new report connections work immediately. Set aside because it destroys the per-user audit trail and forces RLS into Power BI, which violates ADR-004 if implemented as DAX and reintroduces security logic into the display layer.

### Option C: Hybrid — service account for standard reports, per-user for sensitive data (set aside)

Its genuine advantage: not all staff need individual Snowflake accounts, so provisioning effort tracks sensitivity. Set aside because it creates two auth paths to maintain and a classification judgment ("is this report sensitive?") on every connection — the boundary would be relitigated report by report, and a misclassification silently drops the audit trail exactly where it matters most (donor financials, personnel).

## Consequences

**Positive**
- New-user provisioning is a runbook, not an engagement; Gate 4 has a concrete standard to check.
- Security and audit live in one governed place (Snowflake), consistent across Power BI and Cortex Analyst consumers.
- No credential sharing; offboarding is Entra ID-driven.

**Negative**
- Every report consumer needs a Snowflake user, which carries per-user administration and (depending on edition) licensing considerations. [confirm cost implications with Kenny]
- The auth chain has three parties (Entra ID, Snowflake OAuth integration, Power BI tenant); a failure in any one presents to the user as "the report is broken", and diagnosis spans two teams.

**Accepted risks**
- OAuth token or integration misconfiguration during Entra ID tenant changes could interrupt all report access at once; the runbook must include the recovery path.

## Revisit trigger

Reopen if the per-user account count or licensing cost becomes material at scale-out, if Snowflake or Microsoft change the external OAuth integration model, or if a sensitive-data report class emerges that the uniform pattern cannot serve — whichever comes first.
