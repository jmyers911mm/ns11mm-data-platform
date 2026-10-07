# 7.0.0: Security Hygiene

- **Date:** 2026-07-29
- **Version:** 7.0.0

First of six release-readiness patches (7.0.0 → 7.5.0). Major bump: developer setup changes
(the repo-root `profiles.yml` is gone).

## Removed

- **`profiles.yml`** — a committed connection profile carrying the real Snowflake account and
  user identities (docs had claimed it was gitignored; it wasn't). It also contained a
  copy-paste bug (`dev_dsun` target pointed at DSUN's database under the jmyers user).
  **BREAKING:** developers now keep their profile at `~/.dbt/profiles.yml`, created from the
  new template.
- **`git_workspace_setup.sql`** — one-off personal workspace setup that contained a committed
  GitHub PAT. NOTE: deleting the file does not revoke the token — it must be revoked in
  GitHub (it remains in the old repository's history).
- **`.temp/uploads/`** — stale local copies of governed seeds (one missing the Museum Cafe
  facility row, one missing the VTEDU virtual-tour PLUs). Restoring from them would have
  reintroduced fixed bugs.

## Added

- **`profiles.yml.template`** — env-var-driven profile template (targets `dev` / `dev_shared`
  / `ci` / `prod`) with explicit authenticators (SSO for developers, secret-based for CI/prod).

## Changed

- `.gitignore` now explicitly ignores `profiles.yml` (template excepted) and key files
  (`*.pem`, `*.p8`).

---
