# Verified Queries

This folder contains all certified verified queries (VQRs) for Cortex Analyst semantic views and direct Gold table queries.

## Folder Structure

```
analyses/verified_queries/
├── revenue_operations/     (7 VQRs) Revenue trending, fiscal reporting, payment analysis
├── ticket_sales/           (5 VQRs) Ticket pricing, AOV, utilization, discounts
├── visitor_experience/     (2 VQRs) Hourly traffic, gate patterns
├── retail/                 (2 VQRs) Product performance, category analysis
├── membership/             (3 VQRs) Customer LTV, segments, membership programs
├── campaigns/              (1 VQR)  Email marketing performance
├── donor_retention/        (5 VQRs) Cohort retention, survival curves, churn
├── capacity_planning/      (5 VQRs) Availability, demand benchmarks, sold-out slots
└── digital_marketing/      (5 VQRs) ROAS, campaign spend, cross-channel comparison
```

**Total: 35 certified VQRs**

## File Conventions

Each domain folder contains:
- `_registry.md` — governance metadata including question, owner, ADR reference, and tags
- `*.sql` — the verified query SQL

## Query Syntax

Most queries use `SEMANTIC_VIEW()` syntax targeting production semantic views:
```sql
SELECT *
FROM SEMANTIC_VIEW(ns11mm_dw_prod.marts.sv_museum_operations
  METRICS metric1, metric2
  DIMENSIONS dim1.column, dim2.column
  WHERE filter_condition)
```

Digital marketing queries use `{{ ref() }}` syntax directly against Gold tables.

## Semantic Views

| View | Used by | Domains |
|---|---|---|
| `ns11mm_dw_prod.marts.sv_museum_operations` | Operations, Tickets, Retail, Membership, Campaigns | revenue_operations, ticket_sales, visitor_experience, retail, membership, campaigns |
| `ns11mm_dw_prod.marts.sv_donor_retention` | Development, Membership | donor_retention, capacity_planning |

## Governance

- All VQRs require approval before deployment to semantic views
- VQRs tagged `action_required` trigger proactive monitoring alerts
- ADR references link to architecture decision records in `docs/adr/`
- Run `dbt run-operation sync_verified_queries` to list all registered VQRs

## Migration Status

These VQRs were migrated from the POC repo (`jmyers911mm/ns11mm-dbt`). 
Find-and-replace applied: `MUSEUM_DW_PROD.GOLD` → `ns11mm_dw_prod.marts`.
