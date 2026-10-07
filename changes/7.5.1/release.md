# 7.5.1: Rollout Corrections

- **Date:** 2026-07-30
- **Version:** 7.5.1

Patch-application fixes only — no new functionality. Verification of the applied
7.0.0–7.5.0 releases against the source tree found three gaps, corrected here:

## Fixed

- **Release 7.2.0's file payload was not applied** — the CI workflow, release-gate and
  ops macros, and terraform files were still at their 7.1.0 state, and its new files
  (`.sqlfluff`, `.sqlfluffignore`, `terraform/modules/*/variables.tf`,
  `disabled/README.md`) were missing. All restored to the 7.2.0-era content.
- **Deletions and renames from 7.0.0–7.5.0 were skipped** — files that earlier releases
  removed or moved were still present at their old paths (including `profiles.yml` and
  `git_workspace_setup.sql` from 7.0.0 — the security-sensitive removals). Old paths
  removed; new paths confirmed (see RELEASE_NOTES for the full list).
- **`dpr-dashboard/deployed/streamlit_app.py`** was corrupted during application (file
  header pasted mid-dictionary, content duplicated). Replaced with the correct version.

---
