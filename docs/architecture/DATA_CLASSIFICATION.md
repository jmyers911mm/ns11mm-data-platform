# Data Classification & PII Handling

How data in the Museum Data Platform is classified and handled. This is the **repo-level summary**; the authoritative, institution-wide policy is the **Data Governance & Integrity Policy** in the Platform Hub. When they differ, the Hub policy governs — update this file to match.

Everyone who touches the data is responsible for handling it according to its classification.

---

## Classification tiers

| Tier | Meaning | Examples in this platform | Handling |
| --- | --- | --- | --- |
| **Restricted / PII** | Identifies a person directly. | Email addresses, phone numbers, names, CRM contact records. | Least-privilege access only. Never copy outside the warehouse. Never paste into tickets, chat, or screenshots. |
| **Confidential** | Sensitive but not directly identifying. | Donor tiers, lifetime value, membership status, individual transactions. | Access by role. Aggregate before sharing externally. |
| **Internal** | Operational data, not for the public. | Daily/monthly operations summaries, capacity utilization, campaign metrics. | Share within the institution as needed. |
| **Public** | Already public or safe to publish. | High-level attendance totals already in public reporting. | No restriction. |

---

## Where PII lives (and where it doesn't)

PII is concentrated in a small number of models. Know these before you build:

- **`stg_salesforce_nps__contacts` / `silver_sf_crm`** — CRM contacts: names, emails, phones.
- **`dim_customer`** — resolved customers, storing **arrays** of all known emails and phones (`EMAILS`, `PHONES`).
- **`rpt_member_360` / `rpt_customer_ltv`** — member profiles with contact details.
- **Intermediate models** that carry email/phone: `silver_pos_tickets`, `silver_pos_retail`, `silver_shopify`, `silver_sf_marketing_cloud`.
- **`fct_ticket_sales`** — carries `customer_email` and `customer_phone` for identity resolution.

**Masking policies** are automatically applied to all PII columns via `on-run-end` hooks:
- `MASK_NAME` — full redaction for non-privileged roles
- `MASK_EMAIL` — shows only `***@domain.com`
- `MASK_PHONE` — shows only last 4 digits

**Row access policy** (`RAP_PII_ACCESS`) prevents `ML_ROLE` from seeing rows with PII values.

By design, **fact and report tables reference people by `customer_id`**, not by raw email/phone — so most analytics never touch PII directly. Keep it that way: join to identifiers only when the use case genuinely requires it.

---

## Rules for handling PII

1. **Least privilege.** Only roles that need PII get it. The `POWERBI_ROLE` and `ML_ROLE` are granted on Gold/ML tables; they should not need raw identifier columns.
2. **Stay in the warehouse.** Don't export PII to local files, spreadsheets, or external tools. Don't put it in commit messages, PR descriptions, issues, logs, or screenshots.
3. **Reference by `customer_id`.** When building downstream models, carry the resolved `customer_id`, not the email/phone, unless the email/phone is the actual deliverable (e.g., a marketing send list — which has its own controls).
4. **Mask in shared contexts.** Sample data shown in docs, demos, or the Hub must be masked or synthetic.
5. **The identity graph is sensitive.** `raw_customer_identifiers` and `dim_customer` map a person's multiple identities together — treat them as Restricted.
6. **Bronze is immutable.** Raw source data (including PII) is never edited in place; corrections happen downstream. This preserves auditability.

---

## Access control in practice

Access is provisioned through Snowflake RBAC roles (see [SNOWFLAKE_SETTINGS](../../SNOWFLAKE_SETTINGS.md)):

| Role | PII Access | Scope |
|---|---|---|
| `ACCOUNTADMIN` / `DEPLOY_PROD_ROLE` | Full (unmasked) | All schemas |
| `TRANSFORMER_ROLE` / `DEPLOY_DEV_ROLE` | Full (unmasked) | Dev schemas |
| `POWERBI_ROLE` | Masked (***@domain) | MARTS only |
| `ML_ROLE` | Row-filtered (no PII rows visible) | INTERMEDIATE + MARTS + ML_FEATURES |
| `LOADER_ROLE` | None (write-only to RAW) | RAW schema |

Masking and row access are enforced automatically by Snowflake policies — no application-level checks needed.

To request or change access, contact Jeremy Myers.

---

## Classification on new models

When you add a model that carries PII or sensitive fields:

- [ ] Mark the PII columns in the model's `schema.yml` (description and any classification meta your team uses).
- [ ] Confirm the model's grants don't over-expose identifier columns.
- [ ] If it introduces a new category of sensitive data, note it in the Hub's Data Classification Record.
- [ ] If it changes who can see PII, that's likely a governance change — check the change-gate tiers in [CONTRIBUTING](../../CONTRIBUTING.md#change-gate-classification).

---

## Related

- **Data Governance & Integrity Policy** (Hub) — the authoritative policy.
- **Access Grant Matrix** (Hub) — who can access what.
- [README → Access Control & Grants](../../README.md#access-control--grants) — how grants are applied technically.
- [Documentation Map](../README.md) — everything else.
