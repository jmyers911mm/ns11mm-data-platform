# ADR-007: Bronze Layer Immutability: Standalone Rule and Exception Process

**Status:** Proposed (drafted from the ADR Review working document; decision pending the Jeremy/Diana review session)
**Category:** Ingestion
**Date:** August 5, 2026
**Deciders:** Jeremy Myers (VP AI & Analytics)
**Consulted:** Diana (Data & AI Team); Michael Cartier (CIO) for the exception sign-off authority
**Related:** ADR-001 (Stack Selection), ADR-002 (Medallion Architecture), ADR-003 (Ingestion Strategy), ADR-012 (Retention), ADR-014 (Change Validation), ADR-015 (Monitoring), ADR-019 (Single Source Database)

> **Source note.** Drafted from the ADR Review working document (Part 2, ADR-007). The review doc's decision box is empty: no option has been formally selected, so this draft records the recommended option pending the session. **Numbering caution:** an earlier in-repo sequence assigned 007 to the Drupal Ingestion Path; this file uses the external register's numbering (007 = Bronze Immutability) per the register-collision note in the [ADR index](README.md). Resolve the collision (owner: Jeremy) before ratification.

## Context

Bronze (RAW) immutability is referenced as a rule in ADR-001, ADR-002, and ADR-003, but no single ADR owns it as a standalone decision with an exception process. This is a governance gap: when an engineer asks "can I use the Salesforce native connector even though it uses merge semantics?", no document formally answers the question or defines the path to an exception.

The rule interacts with real machinery already in place: RAW in `NS11MM_DW_DEV` is append-only and written only by `LOADER_ROLE` (ADR-019 depends on this to bound the blast radius of the shared-source-database decision), and the `gdpr_anonymize` right-to-erasure process already performs targeted writes against RAW — an existing, governed carve-out that this ADR must acknowledge rather than pretend away.

What is not yet known: whether any Wave source genuinely cannot be ingested append-only, and what the retention/deletion policy (ADR-012, proposed) will require.

## Decision

Bronze append-only is a **hard rule, not a preference**.

- Every source lands append-only and write-once into RAW via the custom Python pipeline standard (ADR-003).
- **Snowflake Streams CDC is the approved workaround** for sources whose upstream exposes only merge or change-data semantics: change capture happens without violating RAW append-only.
- **Formal exception process:** any source that genuinely cannot be ingested append-only, and any deletion requirement against RAW (beyond the existing governed `gdpr_anonymize` erasure path), requires a formal ADR amendment signed by Jeremy Myers and Michael Cartier. Exceptions are logged in this ADR's amendment history; there are no silent per-source waivers.

## Options considered

### Option A: Hard rule with documented exception process (recommended)

Append-only is non-negotiable by default; Streams CDC is the approved path for merge-semantics connectors; anything else is a signed, logged exception. Wins because the immutability guarantee is what protects audit and lineage integrity — the reason native connectors were rejected in ADR-003 — and a rule with a defined exception path is enforceable where a preference is not.

### Option B: Soft preference (set aside)

Append-only strongly preferred, but the engineer may use merge semantics with Jeremy's per-source approval. Genuinely simpler operationally, and faster when a source resists append-only. Set aside because per-source verbal approvals leave no record, and the governance guarantee that downstream ADRs (ADR-014 non-regression, ADR-015 monitoring) build on becomes only as strong as memory.

### Option C: Drop the rule; document the actual pattern per source (set aside)

Pragmatic and honest about heterogeneity. Set aside because it surrenders the immutability guarantee entirely: audit and lineage integrity would vary by source, and RAW would no longer be a trustworthy replay substrate.

## Consequences

**Positive**
- One document formally answers every "can I use connector X?" question.
- Audit and lineage integrity are guaranteed platform-wide, not per-source.
- ADR-014 and ADR-015 can rely on RAW as a stable comparison baseline.

**Negative**
- Sources with merge-only upstreams carry the extra engineering cost of the Streams CDC pattern.
- Deletion requests (PII, right-to-erasure beyond the existing `gdpr_anonymize` path) require a formal amendment, which is slower than an operational decision.

**Accepted risks**
- The exception process depends on two named individuals (Jeremy, Michael Cartier); an urgent exception during an absence has no defined delegate. [confirm whether a delegate should be named]

## Revisit trigger

Reopen if a Wave source is found that genuinely cannot be ingested append-only even via Streams CDC, when ADR-012 (retention and archival) defines deletion obligations that conflict with this rule, or at the December 2026 go-live review — whichever comes first.
