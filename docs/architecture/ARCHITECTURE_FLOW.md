# NS11MM Data Platform — Architecture Flow

> **Current scope (July 2026):** only the Gateway (ticketing) and CounterPoint (retail POS)
> sources are connected, feeding the Daily Performance Report. All other sources and domains
> are scaffolded but `enabled=false` until those data connections are established.

```
┌─────────────────────────────────────────────────────────┐
│                    Source Systems                       │
│      Gateway (ticketing)  ·  CounterPoint (retail POS)  │
│             + future: CRM, donations, web, ads          │
└──────────────────────────┬──────────────────────────────┘
                           │  Python pipelines (extract & load)
                           ▼
┌─────────────────────────────────────────────────────────┐
│              Snowflake  ·  RAW schema                   │
│               immutable landing zone                    │
└──────────────────────────┬──────────────────────────────┘
                           │  dbt
                           ▼
┌─────────────────────────────────────────────────────────┐
│              STAGING  (views)                           │
│          rename · cast · deduplicate                    │
└──────────────────────────┬──────────────────────────────┘
                           │  dbt
                           ▼
┌─────────────────────────────────────────────────────────┐
│           INTERMEDIATE  (incremental)                   │
│              business logic applied                     │
└──────────────────────────┬──────────────────────────────┘
                           │  dbt
                           ▼
┌─────────────────────────────────────────────────────────┐
│         MARTS  (dims · facts · report views)            │
└──────────┬─────────────────────────┬────────────────────┘
           │                         │
           ▼                         ▼
┌──────────────────┐     ┌───────────────────────────────┐
│    Power BI      │     │   Cortex Semantic Views        │
│   Dashboards     │     │   (natural-language / AI)      │
└──────────────────┘     └───────────────────────────────┘

           │  MARTS also feeds
           ▼
┌─────────────────────────────────────────────────────────┐
│   ML_FEATURES  →  Snowflake ML Models                   │
└─────────────────────────────────────────────────────────┘

        ════════════════════════════════════════
                    GitHub Actions
          CI/CD · tests every PR · deploys on merge
        ════════════════════════════════════════
```
