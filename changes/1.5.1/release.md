# 1.5.1: Governance: ADR-001 through ADR-006 Rewritten for Snowflake

- **Date:** 2026-07-13
- **Version:** 1.5.1

Six architecture decision records added to `docs/adr/` as markdown, rewritten to their
post-migration state from the ADR Review working document (Part 1 status summary). Four
carried revisions (001, 002, 003, 005); two are current and rendered as-is (004, 006).
Filenames follow the existing `docs/adr/NNNN-title.md` convention. These supersede the
pre-migration text and must be reconciled against the canonical ADRs before the old copies
are retired — see Notes. Companion artifact: `adr_review_working.docx`.

## ADRs Added / Revised

- **`0001-stack-selection.md`** — removed all Microsoft Fabric references; added the
  Snowflake migration rationale, the custom Python ingestion decision, and Cortex Analyst
  as the T3-tier analytics tool
- **`0002-medallion-architecture.md`** — mapped the Fabric lakehouse layers to Snowflake
  schema equivalents (Bronze/Silver/Gold → RAW/INTERMEDIATE/MARTS); added Cortex Analyst
  as a Gold-layer consumer alongside Power BI
- **`0003-ingestion-strategy.md`** — full rewrite. Custom Python pipelines set as the
  standard path to Bronze; native/managed connectors rejected as primary (exception process
  only); Snowflake Streams CDC named as the merge-semantics workaround; two-hop on-prem
  pattern (bcp → RDP → PUT/COPY INTO) documented
- **`0004-no-logic-in-power-bi.md`** — rendered current, no revision. Records the thin-display
  boundary and that row-level security lives in Snowflake, not Power BI DAX
- **`0005-metric-definition-gate.md`** — added the clause extending the gate to the Snowflake
  Cortex Analyst semantic model YAML; recorded that the gate fires on new definitions, not on
  new consumers of existing ones
- **`0006-change-management.md`** — rendered current, no revision to the decision. Captures the
  single-intake path (Ginabell), `ITCHG-NNNN` IDs, PR-gated CI, and commemoration/event freeze
  protocols; ADR-014 forward reference pending

## Notes / To Reconcile

- **Reconstructed, not transcribed.** The review doc supplied status and required revisions for
  001–006, not their full source bodies; the prose was rebuilt from that summary plus current
  platform context. Each file carries `[confirm]` markers for values only the canonical ADR holds
  (original decision dates; exact production schema names in 0002; the seven stage names in 0006;
  Kenny Yeung schema confirmation in 0003)
- **Supersession.** `0005-metric-definition-gate.md` and `0006-change-management-tiers.md` already
  exist in the repo. New 0005 extends the existing gate; new 0006 is titled "Seven-Stage Process"
  where the existing file is "Change Management Tiers (Tier 1/2/Emergency)" — confirm which framework
  is current, then rename/retire the superseded file
- **Register collision to resolve before ADR-007+.** The review doc proposes ADR-007 (Bronze
  Immutability) and ADR-008 (Semantic Layer Governance), but the repo already holds
  `0007-drupal-ingestion-path.md` and `0008-retail-source-split.md`. The register needs
  de-collision before any 007+ ADRs are written
