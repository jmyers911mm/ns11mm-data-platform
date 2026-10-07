# 7.5.2: Snowflake-Native dbt Profile

- **Date:** 2026-07-30
- **Version:** 7.5.2

7.0.0 removed the committed `profiles.yml` for security — correct for local/CI use, but
it also removed the file that **dbt Projects on Snowflake** (`EXECUTE DBT PROJECT` /
Workspaces) reads from the project root. This release restores that path safely.

## Added

- **Root `profiles.yml` (credential-free, committed)** — routes role / warehouse /
  database / schema per target (`dev` / `dev_shared` / `prod`) for Snowflake-native
  execution. Contains no account, user, password, or keys — execution inside Snowflake
  uses the calling session's identity. Never add credentials to it.

## Changed

- `.gitignore` no longer ignores `profiles.yml` (it is credential-free by design now);
  the never-commit-credentials rule is stated in the file itself and in CONTRIBUTING.
- CI (`dbt-ci.yml`) pins `DBT_PROFILES_DIR` to `~/.dbt` in both jobs so the root
  profile never shadows the CI profile built from `profiles.yml.template`.
- CONTRIBUTING / ONBOARDING document the two-profile split (Snowflake-native root
  profile vs. `~/.dbt` for local and CI).

---
