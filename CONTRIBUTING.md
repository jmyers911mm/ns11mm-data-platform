# Contributing

## Branch Strategy: Trunk-Based Development

```
main (production)
 ├── feature/add-donor-segments      ← short-lived (1-3 days max)
 ├── feature/fix-retail-reconcile    ← short-lived
 └── feature/update-campaign-dims    ← short-lived
```

### Rules

1. **`main` is always deployable** — all code on main runs successfully in prod
2. **Feature branches are short-lived** — merge within 1-3 days, never more than a week
3. **No `develop` branch** — we're a small team, no need for integration staging
4. **Deploy from main** — after merge, deploy via `CREATE DBT PROJECT`

### Workflow

```powershell
# 1. Navigate to your local repo

cd C:\Users\<your-username>\ns11mm-data-platform
>>>>>>> remote

# 2. Configure Snowflake CLI (see Snowflake CLI Setup section below)
>>>>>>> remote
#    Set password as environment variable (never hardcode in scripts)
$env:SNOWFLAKE_PASSWORD = "<your_password>"

snow connection test --connection museum    # approve DUO notification
>>>>>>> remote

# 3. Clone the repo (first time only)
git clone https://github.com/ns11mm/ns11mm-data-platform.git
cd ns11mm-data-platform
>>>>>>> remote

# 4. Set up Python + dbt (first time only)
py -3.12 -m venv .venv
& .venv\Scripts\Activate.ps1
pip install dbt-core dbt-snowflake
>>>>>>> remote

# 5. Pull latest from main
>>>>>>> remote
git pull origin main

# 6. Create a feature branch
git checkout -b feature/<your_branch_name>

# 7. Stage and commit changes
git add .
git commit -m "feat: <describe your changes>"

# 8. Push to remote
git push -u origin feature/<your_branch_name>

# 9. Create the PR (GitHub CLI — first time: winget install --id GitHub.cli && gh auth login)
gh pr create --title "<PR title>" --body "<PR description>" --base main --head feature/<your_branch_name>


# 10. After PR is merged, build in your personal dev
git checkout main
git pull origin main
dbt build
>>>>>>> remote
```

### Commit Messages

```
feat: add donor retention cohort model
fix: resolve hashdiff null handling in stg_pos_retail
refactor: move gold models into subfolders
test: add orphan detection for member360
docs: update runbook with quarantine steps
```

---

## Environment architecture

```
NS11MM_DW_DEV_JMYERS    ← Jeremy personal sandbox  (TRANSFORMER_ROLE)

>>>>>>> remote
NS11MM_DW_DEV           ← Shared dev / integration  (DEPLOY_DEV_ROLE — Jeremy only)
NS11MM_DW_PROD          ← Production                (DEPLOY_PROD_ROLE — Jeremy only)
```

Personal dev databases isolate each developer's model builds — nothing you run locally affects anyone else. The shared RAW schema in `NS11MM_DW_DEV` is readable by all environments and is where ingestion pipelines land data.

The flow is: **personal sandbox → PR → shared dev → prod**. Developers never touch shared dev or prod directly. This is enforced at the Snowflake RBAC level — attempting to write to shared dev or prod with `TRANSFORMER_ROLE` will fail.

When a new developer joins, Jeremy creates `NS11MM_DW_DEV_<USERNAME>` and grants `TRANSFORMER_ROLE`.


>>>>>>> remote
---

## Schema names

| Layer | Schema in Snowflake |
|---|---|
| Staging (raw views) | `STAGING` |
| Intermediate (silver) | `INTERMEDIATE` |
| Gold (dimensions, facts, reports) | `MARTS` |
| ML Features | `ML_FEATURES` |
| Raw ingestion | `RAW` |


---

## Release Process

### How a change goes from idea to production

```

VS Code (local)  →  GitHub PR  →  NS11MM_DW_DEV_JMYERS  →  NS11MM_DW_DEV  →  NS11MM_DW_PROD
                         │                │                       │                    │
                    CI validates      TRANSFORMER_ROLE       DEPLOY_DEV_ROLE     DEPLOY_PROD_ROLE
                    (auto)           (you, daily)           (you, after PR)     (you, after validation)
>>>>>>> remote
```

### Step by step

| Step | What to do | Role | Command |
|------|-----------|------|---------|
| 1 | Develop in VS Code or Snowsight workspace | — | Edit files |
| 2 | Build in your personal sandbox | `TRANSFORMER_ROLE` | `dbt build` |
| 3 | Validate locally | `TRANSFORMER_ROLE` | `dbt run-operation validate_before_deploy` |
| 4 | Push & open PR | — | `git push` → open PR on GitHub |
| 5 | CI validates automatically | — | GitHub Actions: parse + compile + lint |
| 6 | Merge to main | — | Approve PR + merge |
| 7 | Promote to shared dev | `DEPLOY_DEV_ROLE` | `dbt build --target dev_shared` |
| 8 | Validate shared dev | `DEPLOY_DEV_ROLE` | Compare row counts DEV_JMYERS vs DEV |
| 9 | Promote to production | `DEPLOY_PROD_ROLE` | `dbt build --target prod` |
| 10 | Update CHANGELOG.md | — | Document what shipped |

### Validation between tiers
>>>>>>> remote
```sql
-- Compare personal dev vs shared dev
SELECT 'JMYERS' as env, COUNT(*) as rows FROM NS11MM_DW_DEV_JMYERS.MARTS.FCT_TICKET_SALES
UNION ALL
SELECT 'SHARED_DEV', COUNT(*) FROM NS11MM_DW_DEV.MARTS.FCT_TICKET_SALES;

-- Compare shared dev vs production
SELECT 'DEV' as env, COUNT(*) as rows FROM NS11MM_DW_DEV.MARTS.FCT_TICKET_SALES
UNION ALL
SELECT 'PROD', COUNT(*) FROM NS11MM_DW_PROD.MARTS.FCT_TICKET_SALES;
```
>>>>>>> remote
### Rollback

If something goes wrong in production:

```sql
-- Option 1: Time Travel (up to 14 days)
CREATE OR REPLACE TABLE NS11MM_DW_PROD.MARTS.FCT_TICKET_SALES
  CLONE NS11MM_DW_PROD.MARTS.FCT_TICKET_SALES AT (OFFSET => -3600);

-- Option 2: Restore from weekly backup clone (Sundays 2 AM)
CREATE OR REPLACE TABLE NS11MM_DW_PROD.MARTS.FCT_TICKET_SALES
  CLONE NS11MM_DW_PROD_BACKUP.MARTS.FCT_TICKET_SALES;

-- Option 3: Rebuild from shared dev
dbt run --target prod --select fct_ticket_sales
```

### Automated daily build

The deployed dbt project runs automatically at 6 AM ET via `TASK_DAILY_DBT_BUILD`:

```sql
-- To execute manually:
EXECUTE DBT PROJECT NS11MM_DW_DEV.PUBLIC.NS11MM_DATA_PLATFORM ARGS = 'build';
```

### After merging a breaking change

If the PR includes schema changes to incremental models:

```bash
dbt build --target prod --full-refresh --select changed_model+
```

---

## Ownership Zones

### Model Groups

| Group | Owner | Models | Responsibility |
|-------|-------|--------|----------------|
| `daily_operations` | Museum Analytics Team | stg_pos_tickets → silver_pos_tickets → fct_daily_operations → fct_monthly_operations, fct_visitor_traffic, dim_gate, dim_date | Ticket sales, gate scans, retail ops |
| `member_engagement` | Membership & Development | stg_sf_crm → silver_sf_crm → fct_member_360 → dim_member | CRM data, member profiles, engagement |
| `donor_retention` | Membership & Development | fct_donor_retention → fct_donor_cohort_survival → ml_donor_churn_features | Cohort analysis, churn prediction |
| `campaign_analytics` | Marketing Team | stg_sf_marketing_cloud → silver_sf_marketing_cloud → fct_campaign_performance → dim_campaign | Email campaigns |
| `visitor_forecasting` | Data Science Team | ml_daily_visitor_features, ml_member_churn_features | ML feature tables |

### Rules of Engagement

1. **You own your group's models** — you can modify them freely on your feature branch
2. **Shared models need coordination** — if you need to change a model in someone else's group, tag them on the PR
3. **Silver models are shared infrastructure** — changes to silver require agreement from all downstream group owners
4. **Breaking changes require a heads-up** — if your change will require downstream `--full-refresh`, notify the team in advance

### Who reviews what

| Changed file | Required reviewer |
|-------------|-------------------|
| `models/raw/*` | JMYERS (infra owner) |
| `models/intermediate/*` | JMYERS (infra owner) |
| `models/marts/facts/fct_donor_*` | Membership team lead |
| `models/marts/facts/fct_daily_*` | Analytics team lead |
| `models/marts/facts/fct_campaign_*` | Marketing team lead |
| `models/ml_features/*` | Data Science team lead |
| `macros/*` | JMYERS (infra owner) |
| `dbt_project.yml` | JMYERS (infra owner) |
| `profiles.yml` | JMYERS (infra owner) |

---

## Developer Targets

### Running dbt in your personal sandbox (daily workflow)

```bash
dbt build                              # uses default target: dev (personal DB)
dbt build --select my_model+           # build specific model + downstream
dbt test --select my_model             # run tests on specific model
```

### Comparing your output to shared dev (read-only)

```sql
-- Query shared dev to compare (TRANSFORMER_ROLE has read access)
SELECT COUNT(*) FROM NS11MM_DW_DEV.MARTS.FCT_DAILY_OPERATIONS;
SELECT COUNT(*) FROM NS11MM_DW_DEV_JMYERS.MARTS.FCT_DAILY_OPERATIONS;
```

### Promoting to shared dev (Jeremy only)

```bash
# Switch to DEPLOY_DEV_ROLE in your session, then:
dbt build --target dev_shared
```

### Promoting to production (Jeremy only)

```bash
# Switch to DEPLOY_PROD_ROLE in your session, then:
dbt build --target prod
# Or via native dbt project:
# EXECUTE DBT PROJECT NS11MM_DW_PROD.INTERMEDIATE.NS11MM_DBT ARGS = 'build';
```

**If you get `Insufficient privileges` when running `--target dev_shared` or `--target prod`, you do not have the required role.** Contact Jeremy.

---

## Pre-PR Checklist

Before opening a pull request, verify:

- [ ] `dbt compile` passes with no errors
- [ ] `dbt build --select your_model+` passes in your dev database
- [ ] All new models have entries in the appropriate `schema.yml`
- [ ] New models have a `group` config if they belong to a domain
- [ ] Tests added for any new business logic
- [ ] `CHANGELOG.md` updated with your changes
- [ ] If changing silver/staging, all downstream tests still pass: `dbt test`
- [ ] If adding a new source, updated circuit breaker + rerun_from_source
- [ ] `dbt run-operation validate_before_deploy` shows no FAIL results
- [ ] If Tier 1 change: change gate approval obtained (see below)

---

## Change Gate Classification

Per the NS11MM IaC policy, changes are classified by tier. This applies to the dbt project as well as infrastructure.

### Tier 1 — Infrastructure Changes (72-hour notice + approval required)

Any change to these files is a Tier 1 change:

| File | Why it's Tier 1 |
|------|-----------------|
| `dbt_project.yml` | Controls all model materializations, hooks, and vars |
| `profiles.yml` | Controls database/warehouse routing |
| `macros/data_quality/check_source_group_readiness.sql` | Circuit breaker — can block all runs |
| `macros/data_quality/check_source_freshness.sql` | Source SLA definitions |
| `macros/generate_schema_name.sql` | Schema routing for all models |
| `.github/workflows/dbt-ci.yml` | CI/CD pipeline definition |
| `scripts/setup_developer_workspace.sql` | Access control and permissions |
| `CODEOWNERS` | PR approval gates |

**Process:**
1. File a Change Log entry (see RUNBOOK.md)
2. Post 72-hour advance notice in Teams data channel
3. Get written approval from JMYERS
4. Merge PR (CODEOWNERS enforces reviewer)
5. Deploy to staging first: `dbt build --target staging`
6. Validate staging, then deploy to prod
7. Post-deploy validation + Teams notification

### Tier 2 — Model Changes (standard PR process)

Any change to model SQL, schema.yml, or tests follows the standard PR workflow:
1. Feature branch → build in dev → PR → CI passes → merge → deploy

### Emergency Changes

If a Tier 1 change is needed urgently (pipeline is down, data is stale):
1. Make the change on a branch
2. Get verbal approval from JMYERS (Teams/Slack/phone)
3. Merge with `[EMERGENCY]` prefix in commit message
4. File the Change Log entry retroactively within 24 hours
5. Post-incident review within 48 hours

---

## Environment Promotion (RBAC-Enforced)

### Three-Tier Promotion Model

```
┌──────────────────────────────┐     ┌──────────────────────────────┐     ┌──────────────────────────────┐
│  PERSONAL DEV                │     │  SHARED DEV                  │     │  PRODUCTION                  │
│  NS11MM_DW_DEV_<USERNAME>    │────▶│  NS11MM_DW_DEV               │────▶│  NS11MM_DW_PROD              │
│                              │     │                              │     │                              │
│  Role: TRANSFORMER_ROLE      │     │  Role: DEPLOY_DEV_ROLE       │     │  Role: DEPLOY_PROD_ROLE      │
│  Who:  Any developer         │     │  Who:  Jeremy only           │     │  Who:  Jeremy only           │
│  When: Feature development   │     │  When: After PR merge        │     │  When: After shared dev      │
│                              │     │                              │     │        validation            │
└──────────────────────────────┘     └──────────────────────────────┘     └──────────────────────────────┘
```

### Role Permissions (enforced by Snowflake RBAC)

| Role | Can Write To | Can Read From | Assigned To |
|------|-------------|---------------|-------------|
| `TRANSFORMER_ROLE` | Personal DB only (`NS11MM_DW_DEV_<YOU>`) | Shared dev (read-only), RAW schema | All developers |
| `DEPLOY_DEV_ROLE` | `NS11MM_DW_DEV` | All personal DBs | Jeremy only |
| `DEPLOY_PROD_ROLE` | `NS11MM_DW_PROD` | `NS11MM_DW_DEV` | Jeremy only |

### Promotion Steps

| Step | dbt Command | Role | Gate |
|------|-------------|------|------|
| 1. Dev build | `dbt build --target dev` | `TRANSFORMER_ROLE` | Tests pass locally |
| 2. Pre-deploy check | `dbt run-operation validate_before_deploy` | `TRANSFORMER_ROLE` | No FAIL results |
| 3. Push & PR | `git push` → open PR | — | CI passes, code review approved |
| 4. Promote to shared dev | `dbt build --target dev_shared` | `DEPLOY_DEV_ROLE` | PR merged to main |
| 5. Validate shared dev | Query shared dev, compare row counts | `DEPLOY_DEV_ROLE` | Models match expectations |
| 6. Promote to prod | `dbt build --target prod` | `DEPLOY_PROD_ROLE` | Shared dev validated |

### Why This Matters

- **Developers cannot accidentally write to shared dev or prod** — Snowflake will reject the query with `Insufficient privileges`
- **All prod changes have an audit trail** — only `DEPLOY_PROD_ROLE` can write, and only Jeremy holds it
- **Rollback is simple** — shared dev is always the last-known-good state; prod can be rebuilt from it

### profiles.yml Targets and Roles

```yaml
dev:          # Personal sandbox — TRANSFORMER_ROLE
dev_shared:   # Shared dev — DEPLOY_DEV_ROLE (Jeremy only)
prod:         # Production — DEPLOY_PROD_ROLE (Jeremy only)
```

If you attempt `dbt run --target dev_shared` without `DEPLOY_DEV_ROLE`, Snowflake will return a permissions error. This is by design.

### Emergency Hotfix Process

If production needs an urgent fix and Jeremy is unavailable:

1. ACCOUNTADMIN can temporarily grant `DEPLOY_PROD_ROLE` to another user
2. Apply the fix with `dbt run --target prod --select broken_model`
3. Revoke the role immediately after
4. File an incident report within 24 hours

**Never skip shared dev for Tier 1 changes.** Model-only changes (Tier 2) may go personal dev → shared dev → prod in rapid succession if CI passes and validate_before_deploy shows MATCH.

---

## Verified Query (VQR) Workflow

Verified queries live in `analyses/verified_queries/` organized by business domain. They are the source of truth for what the Cortex Agent knows how to answer accurately.

### Adding a New VQR

1. **Identify the domain** — pick the folder (`revenue_operations/`, `ticket_sales/`, etc.)
2. **Write the SQL** — create `my_query_name.sql` using `SEMANTIC_VIEW()` syntax:
   ```sql
   SELECT *
   FROM SEMANTIC_VIEW(ns11mm_dw_prod.gold.sv_museum_operations
     METRICS metric1, metric2
     DIMENSIONS dim1, dim2
     WHERE filter_condition)
   ```
3. **Add metadata** — append to the domain's `_verified_queries.yml`:
   ```yaml
   - name: my_query_name
     description: >
       Business context and who uses this.
     file: my_query_name.sql
     semantic_view: NS11MM_DW_PROD.MARTS.SV_MUSEUM_OPERATIONS
     question: "Natural language question this answers"
     stakeholder_owner: Owner Name
     adm_reference: ADR-XXX-XX-XXX
     approved_by: approver_username
     approved_date: "YYYY-MM-DD"
     tags: [domain, certified]
     power_bi_datasets:
       - Dataset Name
   ```
4. **Validate** — run `dbt compile` (ensures SQL parses)
5. **PR and merge** — standard PR process, CI will trigger on `analyses/` changes
6. **Deploy to semantic view** — after merge, rebuild the semantic view with the new VQR in the `AI_VERIFIED_QUERIES` section

### VQR Governance Rules

- All VQRs must have `approved_by` and `approved_date` before deployment
- Only queries tagged `certified` get synced to semantic views
- Run `dbt run-operation sync_verified_queries` to list all registered VQRs
- VQRs tagged `action_required` trigger proactive monitoring alerts

### Removing/Deprecating a VQR

1. Remove the entry from `_verified_queries.yml`
2. Delete the `.sql` file
3. Rebuild the semantic view without that VQR
4. PR with note explaining why (question no longer relevant, data model changed, etc.)

---

## VS Code ↔ GitHub ↔ Snowflake Sync
This workspace (`USER$.PUBLIC."ns11mm-data-platform"`) is a **Git-connected workspace** linked to `https://github.com/ns11mm/ns11mm-data-platform.git`. It automatically syncs with GitHub — no manual copy/publish steps needed.
### Daily workflow (VS Code — recommended)
```bash
# 1. Pull latest from GitHub
git pull origin main

# 2. Create a feature branch
git checkout -b feature/<your_branch_name>
# 3. Make changes, build locally
dbt build --select my_model+

# 4. Commit and push
git add .
git commit -m "feat: describe your changes"
git push -u origin feature/<your_branch_name>
# 5. Open a PR
gh pr create --title "feat: description" --base main
```

### After PR is merged
The Git workspace auto-syncs from GitHub. Changes are immediately visible in Snowsight.
To trigger a manual sync: pull the latest in the workspace file browser.
### Editing in Snowsight workspace
You can also edit directly in the Snowsight workspace browser. Changes you make are committed to a branch in the Git repo. Open a PR from that branch to merge to main.

### Snowflake CLI Setup

Your `%USERPROFILE%\.snowflake\config.toml`:

```toml
[connections.museum]
account = "om01578.east-us.azure"
user = "YOURUSER@911MEMORIAL.ORG"
authenticator = "username_password_mfa"
role = "TRANSFORMER_ROLE"
warehouse = "DBT_DEV_WH"
database = "NS11MM_DW_DEV_<YOUR_USERNAME>"
schema = "MARTS"
```

Test with: `snow connection test --connection museum` (approve Duo push)
---

## SQL Style Guide

See the full [SQL Style Guide](docs/architecture/SQL_STYLE_GUIDE.md). Key points:

- Keywords lowercase (`select`, `from`, `where`)
- One column per line
- CTE-based structure: import CTEs → logical CTEs → `final`
- Use `{{ ref() }}` and `{{ source() }}` — never hardcode database/schema/table
- Run `sqlfluff lint models/` before committing
