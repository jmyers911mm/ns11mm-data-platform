# Onboarding — Data Team

A linear, day-one checklist for new contributors to the `ns11mm/ns11mm-data-platform` project. Work top to bottom; by the end you'll have a working personal workspace and your first successful build.

For the *why* behind any step, follow the links into [CONTRIBUTING](../CONTRIBUTING.md) and the [README](../README.md).

---

## Before you start — access you'll need

Ask Jeremy Myers (VP of AI & Analytics) or the CIO's office to provision these before day one:

- [ ] **GitHub access** to `ns11mm/ns11mm-data-platform` (write access if you'll contribute)
- [ ] **Snowflake account** with `TRANSFORMER_ROLE` granted
- [ ] **A personal dev database** — `NS11MM_DW_DEV_<YOURUSERNAME>` (created via `scripts/setup_developer_workspace.sql`, run by Jeremy)
- [ ] **Read access** to `NS11MM_DW_PROD` (for comparison only — never write to it)
- [ ] **Membership** in the Teams data channel (for change notices and alerts)
- [ ] **Access to the Platform Hub** (registries, runbook, ADR log)

---

## Step 1 — Read the lay of the land (30 minutes)

- [ ] Skim the [README](../README.md) — focus on **Architecture**, **Data Layers**, and **Model Lineage**.
- [ ] Read [CONTRIBUTING](../CONTRIBUTING.md) — focus on **Daily Development Workflow**, **Branch Strategy**, and **PR Checklist**.
- [ ] Read the [SQL Style Guide](architecture/SQL_STYLE_GUIDE.md).
- [ ] Skim [Data Classification](architecture/DATA_CLASSIFICATION.md) so you know what PII looks like before you touch it.
- [ ] Read [PROJECT_MAP](architecture/PROJECT_MAP.md) to understand where everything lives.

You don't need to memorize anything — just know where to look.

---

## Step 2 — Set up your machine

- [ ] Install **Python 3.11** (pinned — matches CI and the ingestion pipelines; do not use 3.13 or 3.14)
- [ ] Clone the repo:
  ```powershell
  git clone https://github.com/ns11mm/ns11mm-data-platform.git
  cd ns11mm-data-platform
  ```
- [ ] Create a virtual environment and install dbt:
  ```powershell
  py -3.11 -m venv .venv
  & .venv\Scripts\Activate.ps1
  pip install dbt-snowflake==1.9.*
  dbt deps
  ```
- [ ] Enable the repo's git hooks (semantic-view DDL drift guard — see [CONTRIBUTING](../CONTRIBUTING.md)):
  ```powershell
  git config core.hooksPath .githooks
  ```

---

## Step 3 — Create your profiles.yml from the template

Copy the repo's [`profiles.yml.template`](../profiles.yml.template) to `C:\Users\<your-name>\.dbt\profiles.yml` (your home `.dbt` folder, **not** the repo root):

```powershell
Copy-Item profiles.yml.template $env:USERPROFILE\.dbt\profiles.yml
```

This home-folder profile is only for running dbt from your own machine. (The repo root
also carries a committed `profiles.yml` — that one is the **credential-free** profile used
by dbt Projects on Snowflake and contains no identity; never add account/user/password to
it.) The template reads your identity from environment variables rather than hardcoding it:

| Env var | Value |
|---|---|
| `SNOWFLAKE_ACCOUNT` | e.g. `<locator>.<region>.azure` |
| `SNOWFLAKE_USER` | your `@911memorial.org` login |
| `DBT_DEV_DATABASE` | your personal dev DB, e.g. `NS11MM_DW_DEV_<YOUR_USERNAME>` (created via `scripts/setup_developer_workspace.sql`) |

Interactive developers authenticate via SSO (`externalbrowser`); CI uses password auth from repository secrets (see `.github/workflows/dbt-ci.yml`).

Ask Jeremy for your personal dev database name if it hasn't been provisioned yet.

---

## Step 4 — Set your environment variables and test the connection

In every new terminal session before running dbt:

```powershell
$env:SNOWFLAKE_ACCOUNT = "<account>"
$env:SNOWFLAKE_USER = "<you>@911memorial.org"
$env:DBT_DEV_DATABASE = "NS11MM_DW_DEV_<YOUR_USERNAME>"
dbt debug --target dev
```

You should see `Connection test: OK` after completing the browser SSO / Duo prompt.

---

## Step 5 — Load seeds and run your first build

Seeds must be loaded before models that depend on them. The 19 reference seeds land in the dedicated `SEEDS` schema of your personal database:

```powershell
dbt seed --target dev
dbt run --target dev
```

---

## Step 6 — Explore what built

Open Snowsight and query your personal database:

```sql
-- Confirm dim_date built (13,149 rows expected)
SELECT COUNT(*), MIN(date_key), MAX(date_key)
FROM NS11MM_DW_DEV_<YOUR_USERNAME>.MARTS.DIM_DATE;

-- Confirm dim_facility built
SELECT * FROM NS11MM_DW_DEV_<YOUR_USERNAME>.MARTS.DIM_FACILITY;

-- Confirm seeds landed in the SEEDS schema
SHOW TABLES IN SCHEMA NS11MM_DW_DEV_<YOUR_USERNAME>.SEEDS;
```

Or generate and view dbt docs locally:

```powershell
dbt docs generate --target dev
dbt docs serve
```

---

## Step 7 — Make your first change

Follow the workflow in [CONTRIBUTING](../CONTRIBUTING.md):

```powershell
git checkout -b feature/my-first-change
# make a change
dbt run -s <model_name> --target dev
dbt test -s <model_name> --target dev
git add .
git commit -m "feat: describe what you changed"
git push -u origin feature/my-first-change
gh pr create --base main
```

---

## Environment architecture reminder

```

NS11MM_DW_DEV_<YOUR_NAME>   ← your personal sandbox (TRANSFORMER_ROLE — full write)
NS11MM_DW_DEV               ← shared dev (DEPLOY_DEV_ROLE — Jeremy only)
NS11MM_DW_PROD              ← production (DEPLOY_PROD_ROLE — Jeremy only)
```


You work exclusively in your personal database. **Snowflake RBAC enforces this** — if you accidentally target shared dev or prod with TRANSFORMER_ROLE, the query will fail with `Insufficient privileges`. This is by design.

### Role summary

| Role | You have it? | What it lets you do |
|---|---|---|
| `TRANSFORMER_ROLE` | ✅ Yes | Read shared dev, write your personal DB |
| `DEPLOY_DEV_ROLE` | ❌ Jeremy only | Write to NS11MM_DW_DEV |
| `DEPLOY_PROD_ROLE` | ❌ Jeremy only | Write to NS11MM_DW_PROD |

