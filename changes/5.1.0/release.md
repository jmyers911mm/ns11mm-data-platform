# 5.1.0: Standardized Header Notes

- **Date:** 2026-07-28
- **Version:** 5.1.0

Session date: 2026-07-28. Applied a consistent documentation header block to all 53 model and test
SQL files. No SQL logic or `{{ config() }}` content was changed — only the comment blocks at the top
of each file were reformatted. Headers now follow a single convention: layer prefix → separator →
Domain / Grain / narrative notes, with `{{ config() }}` consistently placed after the header block.

## Changed

| Area | Change |
|------|--------|
| 3 intermediate budget models | `-- Intermediate:` → `-- Silver intermediate:` prefix; normalized `Grain:` spacing. |
| 6 intermediate DPR models | `-- Silver DPR:` → `-- Silver intermediate:` prefix; removed indent from bullet lists. |
| 4 intermediate retail/gateway models | Moved `{{ config() }}` below header (was above); normalized format. |
| 11 dimension models | Converted `/* ... */` block-comment headers to `--` line-comment format with Domain/Grain/Source structure. |
| 9 fact models | Moved headers above `{{ config() }}` where needed; changed `-- Mart fact:` → `-- Marts fact:`; normalized `Grain:` spacing. |
| 11 report models | Moved headers above `{{ config() }}`; normalized `Grain:` spacing; removed indent from bullet lists. |
| 1 ML feature model | Removed stale one-liner description; normalized header. |
| 8 test files | Replaced single-line descriptions with `-- Test (category):` format and added `-- Severity:` annotation. |

## Convention (all 53 files)

```
-- <Layer> <type>: <one-line title>
-- Co-authored with CoCo
-- ---------------------------------------------------------------------------
-- Domain: <domain>
-- Grain: <grain statement>
--
-- <Narrative notes…>

{{ config(…) }}
```

## Migration notes

- **No breaking changes.** SQL output is byte-for-byte identical.
- `{{ config() }}` position moved in ~15 files (from above the header to below). dbt treats position
  as irrelevant — compilation is unaffected.

---
