# Pipeline Refresh Log

Per-table refresh record for ingestion pipeline runs into RAW.

**Mechanism:** `pipelines/shared/refresh_log.py` (`RefreshLogger`) appends a section to this
file each time a pipeline run completes. **There are currently no automated writers** —
ingestion is seed-based (batch exports loaded to RAW) and the function pipelines are
disabled (`disabled/azure-pipelines-*`), so no runs are being logged. Entries will appear
here automatically once the function pipelines go live.

---

| Source | Mode | Run started | Run finished | Records | Status |
|--------|------|-------------|--------------|--------:|--------|
| *(no runs recorded yet)* | — | — | — | — | — |

---
