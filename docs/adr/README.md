# Architecture Decision Records

This folder contains the Architecture Decision Records (ADRs) for the NS11MM Data Platform. Each ADR documents a significant architectural or governance decision: what was decided, why, and what alternatives were considered.

ADRs are the authoritative record of why the platform is built the way it is. When you encounter a design choice that seems unusual, an ADR usually explains it.

---

## ADR index

| ADR | Title | Status |
| --- | --- | --- |
| [ADR-005](0005-metric-definition-gate.md) | Metric Definition Gate | Accepted |
| [ADR-006](0006-change-management-tiers.md) | Change Management Framework | Accepted |
| [ADR-007](0007-drupal-ingestion-path.md) | Drupal CMS Ingestion Path | **Decision Required** |
| [ADR-008](0008-retail-source-split.md) | Retail Source Split (CounterPoint vs Shopify) | **Decision Required** |

---

## How to read an ADR

Each ADR contains:

- **Status** — Proposed, Accepted, Deprecated, or Superseded
- **Context** — The problem or situation that required a decision
- **Decision** — What was decided
- **Consequences** — What this decision means going forward (tradeoffs, constraints, follow-on work)

---

## How to add a new ADR

When a significant architectural decision needs to be made:

1. Create a new file: `docs/adr/00{N}-{short-title}.md` where `{N}` is the next number in sequence
2. Use the structure: Status / Date / Deciders / Context / Options / Decision / Consequences
3. Open a PR — Jeremy Myers is required reviewer for all ADR changes
4. After merge, add the ADR to this index

The bar for writing an ADR: if the decision would affect more than one model, more than one team member, or would be hard to reverse, write an ADR. When in doubt, write one.

---

## Open decisions

Two ADRs are currently blocking work:

**ADR-007 — Drupal ingestion path:** Blocks `stg_drupal__pages.sql` completion. Requires Jeremy + Anna Kim + Kenny.

**ADR-008 — Retail source split:** Blocks `silver_pos_retail.sql` and `fct_retail_line_items.sql`. Recommendation is Option A (unified with channel flag). Requires Jeremy's sign-off.
