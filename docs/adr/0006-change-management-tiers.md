# ADR-006: Change Management Framework

**Status:** Accepted  
**Date:** 2026-04-01  
**Deciders:** Jeremy Myers

## Decision

All changes to the data platform are classified into three tiers:

| Tier | Examples | Process |
|---|---|---|
| Tier 1 | New models, schema changes, new sources, metric definition changes | PR required; domain owner review; Jeremy approval; full dbt build in dev before merge |
| Tier 2 | Bug fixes, column additions, documentation updates, test additions | PR required; Jeremy approval; slim CI acceptable |
| Emergency | Production data incident requiring immediate fix | Jeremy direct commit to main permitted; post-incident PR documenting change required within 24h |

## Rationale

Tier 1 changes have downstream impacts on Power BI, ML models, and Cortex Analyst. They require more scrutiny. Tier 2 changes are lower risk and can move faster. Emergency provision exists to avoid blocking incident recovery on process.
