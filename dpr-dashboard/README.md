# DPR Dashboard — Streamlit App

Daily Performance Report dashboard showing YoY comparisons for museum operations metrics (attendance, revenue, donations, retail).

## Two Versions of `streamlit_app.py`

| File | Runtime | Connection Pattern | Use Case |
|------|---------|-------------------|----------|
| `streamlit_app.py` | **Container runtime** (Workspace) | `st.connection("snowflake", ttl=...)` | Development and preview inside Snowsight Workspaces |
| `deployed/streamlit_app.py` | **Warehouse runtime** (deployed) | `get_active_session()` from Snowpark | Shared, standalone app with a URL others can access |

**Why two versions?**

Snowflake has two Streamlit hosting modes with incompatible connection APIs:

1. **Workspace (container runtime)** — runs on a compute pool, supports modern Streamlit APIs (`st.connection`, `st.rerun`, `st.divider`, `border=True` on `st.metric`). This is what you use during development.

2. **Deployed (warehouse runtime)** — runs on a virtual warehouse via `CREATE STREAMLIT`, uses an older bundled Streamlit that requires `get_active_session()` and lacks newer APIs. This is what produces a shareable URL.

The `deployed/` version strips unsupported APIs:
- `st.connection(...)` → `get_active_session()` + `session.sql(...).to_pandas()`
- `st.rerun()` → `st.experimental_rerun()`
- `st.divider()` → `st.markdown("---")`
- `border=True` on `st.metric` → removed

## Deployment

The deployed app lives at:
```
NS11MM_DW_DEV_JMYERS.MARTS.DPR_DASHBOARD
```

Backed by stage: `@NS11MM_DW_DEV_JMYERS.MARTS.DPR_DASHBOARD_STAGE`

### To redeploy after changes:

```sql
-- Push updated file to stage
COPY FILES 
  INTO @NS11MM_DW_DEV_JMYERS.MARTS.DPR_DASHBOARD_STAGE/
  FROM 'snow://workspace/USER$.PUBLIC."ns11mm-data-platform"/versions/live/dpr-dashboard/deployed/'
  FILES = ('streamlit_app.py');
```

### To grant access to other roles:

```sql
GRANT USAGE ON STREAMLIT NS11MM_DW_DEV_JMYERS.MARTS.DPR_DASHBOARD TO ROLE <ROLE_NAME>;
```

## Data Source

Both versions query `NS11MM_DW_DEV_JMYERS.MARTS.FCT_DAILY_PERFORMANCE` which is built by the dbt project.

## Features

- **Yesterday / MTD / YTD** tabs with KPI cards and YoY delta percentages
- **12 metrics**: Museum Attendance, Ticket Revenue, Pass Revenue, Guided Tour Revenue, Field Trip Revenue, Audio Revenue, Museum Store Profit, Cafe Profit, Total Donations, Service Fees, Tickets Sold, Retail Carts Profit
- **Daily trend chart** with metric selector
- **Refresh button** to clear cached data (10-minute TTL)
