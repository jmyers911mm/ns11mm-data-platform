# Data Platform Source Integration Plan

**Project:** NS11MM Data Platform Modernization

**Scope:** Integration of all identified source systems into the Snowflake RAW schema and through the dbt staging layer (STAGING schema)

**Status:** Active v1.0 — 14 sources confirmed; Azure pipeline build in progress

**Grounded against:** vendor API documentation plus `ns11mm/ns11mm-data-platform` structure (sample schemas only, not the real feeds)

---

## 1. Purpose

This plan defines every source system that feeds the platform, the real API or extraction profile for each, and the specific details we need to land and contract each one. The GitHub `sources.yml` reflects sample data, so the schemas there are illustrative only. This version replaces that with the actual connection, authentication, and extraction details per vendor.

Two non-negotiable rules still frame the work. RAW is immutable, so this is landing and contracting raw data only. And no MARTS model or Power BI element may be built on a feed until its metric definitions clear the ADR-005 gate.

---

## 2. Source coverage snapshot

The eight canonical source systems mapped to their real vendor products, with the two paid-media feeds and the derived identity graph included. Vendor names flagged "confirm" are inferred from our naming and should be verified.

| Source system | Real product | Primary access method | Auth model |
|---|---|---|---|
| Ticketing / Gateway | Gateway Ticketing Galaxy (confirm) | Galaxy SQL Server database extract | SQL login |
| Retail POS | Galaxy retail module (confirm) or separate store POS | Same Galaxy database, or separate POS API | SQL login or API |
| Salesforce CRM | Salesforce (NPSP or Nonprofit Cloud, confirm) | REST plus Bulk API 2.0 | OAuth 2.0 |
| Salesforce Marketing Cloud | Marketing Cloud Engagement | REST plus SOAP, or Data Extract to SFTP | OAuth 2.0 server-to-server |
| GA4 / Google Analytics | Google Analytics 4 | BigQuery export or GA4 Data API | Service account OAuth 2.0 |
| Google Ads | Google Ads | Google Ads API | OAuth 2.0 plus developer token |
| Meta Ads | Meta Marketing API | Graph API Insights | OAuth 2.0 system-user token |
| GoFundMe Pro / Classy | GoFundMe Pro (Classy) | Classy REST API | OAuth 2.0 client credentials |
| Vena | Vena Solutions | Vena Export API | HTTP Basic application token |
| General Ledger / NXT | Blackbaud Financial Edge NXT | SKY API General Ledger | OAuth 2.0 plus subscription key |
| Wufoo (forms) | Wufoo online forms | REST API v3 entries, or webhooks | HTTP Basic API key |
| Clicky (web analytics) | Clicky analytics | Stats API v4 | site_id plus sitekey |
| Identity graph | Derived, internal | Built in dbt from other feeds | none |

**Headline unchanged:** the finance and fundraising spine (GoFundMe Pro, Financial Edge NXT, and Salesforce gifts) remains the principal gap. What this version adds is that two of those three have clean, documented APIs, so the build effort is well defined rather than open.

---

## 3. What we need from every source

The common integration contract per feed. A feed is "integrated" only when all of the following are settled.

1. **Connection and auth.** Endpoint or database, auth model, and the specific credentials. All credentials land in Azure Key Vault. SQL logins are preferred over Windows Auth through the On-Premises Data Gateway.
2. **Entities and fields.** The specific objects, endpoints, or tables to extract.
3. **Grain and primary key.** The natural grain and the unique key per landed table.
4. **Extract strategy.** Full versus incremental, and the watermark field where incremental.
5. **Freshness target and SLA tier.** Mapped to Critical (24h), High (72h), or Normal (168h).
6. **Sensitivity classification.** PII or financial flags. No bank, card, or identity numbers are landed.
7. **Bronze landing tables** following the `raw_[system]_[entity]` pattern.
8. **Ownership.** Business owner and `meta.source_system` token.
9. **Downstream and metric dependencies.** The `rpt_` models and ADR-005 metric definitions the feed unblocks.

---

## 4. Per-source API and extraction profiles

### 4.1 Gateway Ticketing Galaxy — ticketing, scans, capacity, retail, membership

- **Product:** Gateway Ticketing Galaxy (current generation Galaxy 8). One platform spans ticketing, admission control, retail, food and beverage, membership and donor management, and reporting.
- **APIs that exist but do not fit extraction:** Galaxy Connect and the OCTO Core API are distribution APIs for selling tickets through OTAs and third-party distributors. The ACS API covers admission control, scanning, order fulfillment, and cancellations. These are transactional and distribution-oriented, not bulk analytics extraction.
- **Realistic extraction path:** direct read access to the Galaxy SQL Server backend, which is the same Galaxy reporting database we are replacing as a reporting tool but can retain as a raw source. This is how sales, scans, capacity, retail, and membership are pulled.
- **Auth:** SQL login, in line with our standard of avoiding Windows Auth and Kerberos delegation through the gateway.
- **Entities:** ticket sales, gate scan events, capacity configuration, retail transactions, food and beverage, membership and pass records.
- **Extract:** incremental by transaction or modified timestamp watermark.
- **Landing path:** Azure Functions copy activity from Galaxy SQL Server into Snowflake Bronze.
- **To confirm:** whether Gateway offers a supported data or reporting API as an alternative to direct DB access, since direct DB reads have vendor-support implications; and whether retail and membership truly live in the same Galaxy database.

### 4.2 Retail POS — likely the Galaxy retail module

- **Product:** most likely Galaxy's retail module, which would make this the same source and database as 4.1 rather than a separate system. If the museum store runs a separate POS, that vendor needs to be identified.
- **What we need:** if Galaxy, fold retail transactions and a product or SKU master into the Galaxy extract. If separate, capture vendor, API or DB access, and the product dimension that the Retail Performance dashboard needs for category rollups.
- **To confirm:** Galaxy module versus separate POS vendor. This is the single fastest item to close.

### 4.3 Salesforce CRM — membership, donors, gifts

- **Product:** Salesforce, almost certainly on NPSP or Nonprofit Cloud given the nonprofit context.
- **APIs:** REST API for general access, Bulk API 2.0 for high-volume nightly extracts, SOAP where needed. OAuth 2.0, with the JWT bearer flow preferred for server-to-server so no interactive login is required.
- **Base:** `https://{myDomain}.my.salesforce.com/services/data/v{version}/`.
- **Objects needed:** Contact, Account or Household, Opportunity (gifts and donations), OpportunityContactRole, Campaign, CampaignMember, and on NPSP the recurring donation and payment objects (`npe03__Recurring_Donation__c`, `npe01__OppPayment__c`), plus the membership object if separate.
- **Extract:** incremental on `SystemModstamp`; Bulk API 2.0 with date-bounded queries, or Change Data Capture for near-real-time.
- **Rate limits:** per-org 24-hour API call allocation plus concurrent Bulk job limits.
- **Landing path:** Azure Functions pipeline or connector into Bronze.
- **To confirm:** NPSP versus Nonprofit Cloud, and the final object list, since the gift object is what unblocks fundraising revenue from CRM.

### 4.4 Salesforce Marketing Cloud — email engagement

- **Product:** Marketing Cloud Engagement.
- **APIs:** REST and SOAP, sharing OAuth 2.0. Server-to-server uses the client credentials grant.
- **Token endpoint:** `https://{subdomain}.auth.marketingcloudapis.com/v2/token`; REST base `https://{subdomain}.rest.marketingcloudapis.com`. The request carries `client_id`, `client_secret`, and `account_id` (the MID).
- **Credentials:** created as a Server-to-Server Installed Package, which requires the Installed Package Administer permission.
- **Data:** tracking events (sends, opens, clicks, bounces, unsubscribes), Data Extensions, and journey or automation metadata. Extraction is either via a Data Extract Activity in Automation Studio that writes a tracking extract as a zip or a Data Extension extract as a CSV to SFTP, or via direct API pulls.
- **Extract:** by event timestamp, or a scheduled Data Extract with an SFTP file drop.
- **Landing path:** SFTP file drop picked up by a Azure Functions pipeline into Bronze, or direct API pull.
- **To confirm:** the tenant subdomain and which business unit MID is authoritative, since wrong subdomain or BU context is the most common failure mode.

### 4.5 GA4 and paid media — digital and marketing

- **GA4 has two extraction routes, and we need to pick one:**
  - **BigQuery export** is the free native link that lands raw event-level data. Every row is an event with nested `event_params` arrays that require UNNEST. This is the right path for granular session and event analysis, but it introduces a BigQuery to Snowflake hop.
  - **GA4 Data API** returns aggregated reports that match the GA4 UI, via a Google Cloud service account on OAuth 2.0. Simpler to land directly, but aggregated and subject to sampling and quotas.
  - **Freshness note:** late-arriving events stabilize after roughly 72 hours, which sets a floor on how fresh GA4-derived metrics can be trusted.
- **Google Ads:** the Google Ads API, authenticated with OAuth 2.0 plus a developer token and a login customer ID. Data is pulled with GAQL queries against campaign, ad group, and metrics resources using searchStream.
- **Meta Ads:** the Meta Marketing API, part of the Graph API. Authenticated with an OAuth 2.0 system-user access token and the `ads_read` permission. Ad performance comes from the Insights edge at `/act_{adAccountId}/insights`, subject to app and account rate limits.
- **Landing path:** API pulls or managed connectors into Bronze for the ad platforms; BigQuery export plus a copy step, or Data API pulls, for GA4.
- **To confirm:** GA4 BigQuery export versus Data API. This is an architecture decision, not a detail.

### 4.6 GoFundMe Pro / Classy — online fundraising

- **Product:** GoFundMe Pro, formerly Classy. The API still lives on the classy.org domain after the rebrand.
- **API:** Classy REST API, OAuth 2.0. The token endpoint is `https://api.classy.org/oauth2/auth`, exchanged for an access token used on subsequent calls.
- **Credentials:** a client ID and client secret created under Apps and Extensions, plus the Organization or Tenant ID, which appears in the admin URL.
- **Entities:** transactions and donations, campaigns, fundraising pages and teams, source codes for attribution, and multi-item orders for Giving Cart campaigns. Bulk offline donation upload exists for the reverse direction.
- **Rate limits:** a 429 Too Many Requests response with a retry after roughly 24 seconds.
- **Landing path:** API pulls into Bronze, credentials in Key Vault.
- **Why it matters:** one leg of the revenue reconciliation triangle, and a primary donor analytics input.

### 4.7 Vena — planning and budget versus actual

- **Product:** Vena Solutions FP&A.
- **API:** Public API at `https://{hub}.vena.io/api/public/v1/`, where hub is the regional host such as us2. Authentication is HTTP Basic Auth using an Application Token, with `apiUser` as the username and `apiKey` as the password, created under Admin then Application Tokens with token permissions assigned.
- **Export API endpoints:** the Intersections endpoint returns data values at bottom-level dimension intersections, and the Hierarchy endpoint returns dimension hierarchies. Output is JSON or CSV via the Accept header. Calls are scoped to a model ID.
- **Rate limits:** 429 when exceeded; tune the pageSize parameter.
- **Landing path:** Export API pulls into Bronze, or the prebuilt Vena integration for Azure Functions, which fits our orchestration layer directly.
- **Gotcha:** the Intersections endpoint returns only leaf-level values and does not roll up to parent members, so all aggregation must happen downstream in dbt.

### 4.8 Blackbaud Financial Edge NXT — general ledger

- **Product:** Blackbaud Financial Edge NXT, the cloud nonprofit accounting system. General ledger is its foundation, and all module transactions post into its accounts and projects.
- **API:** SKY API on the Blackbaud developer portal. OAuth 2.0 on a Blackbaud ID, plus a subscription key sent as a request header. Setup requires a Blackbaud ID, an admin-level action in the environment to enable access, and a developer application.
- **Endpoints:** the General Ledger API for accounts, journal entries, transactions, and projects, with Payables and a now-GA Receivables API alongside it.
- **Extract:** incremental by post or modified date.
- **Landing path:** SKY API pulls into Bronze, or the prebuilt Power Platform connector for Financial Edge NXT General Ledger. Credentials and refresh tokens in Key Vault.
- **Gotcha:** some older GL endpoints are deprecated; build only against the current endpoints, and plan for OAuth refresh token rotation.
- **Why it matters:** the financial system of record and the reconciliation anchor in section 5.

### 4.9 Wufoo — online forms

- **Product:** Wufoo, a hosted form builder in the SurveyMonkey family. The platform collects whatever the museum's published forms capture, which typically spans event and program registration, inquiry and contact forms, and volunteer or group requests.
- **API:** Wufoo REST API v3. Base `https://{subdomain}.wufoo.com/api/v3/`, returning JSON or XML.
- **Auth:** HTTP Basic Auth where the account API key is the username and the password is ignored. The key is found in Wufoo's Code Manager. The host may be wufoo.com or a regional variant such as wufoo.eu, so the subdomain and ccTLD both matter.
- **Entities:** forms, fields, entries (the submissions, and the primary data we want), reports, users, and entry comments.
- **Extract:** incremental polling of the entries endpoint filtered on DateCreated or DateUpdated, on a schedule. Webhooks on form submission are also available, up to ten per form, sent as an HTTP POST with an optional handshake key and field metadata, as a near-real-time alternative if a receiver endpoint exists.
- **Rate limits:** entry submission is capped at fifty per user in a rolling five-minute window with a 429 on exceed. Reads are lighter, but polling should still be paced.
- **Sensitivity:** forms generally collect names, emails, and phone numbers, so this is PII. If any form collects payment or identity numbers, those fields are excluded from Bronze under our landing rules.
- **Landing path:** scheduled Azure Functions pull of new entries per form into Bronze, credentials in Key Vault.
- **To confirm:** which forms are in scope and which domains they feed, likely Education program registration, Operations group or volunteer requests, and Marketing inquiries, plus the form owner.

### 4.10 Clicky — web analytics

- **Product:** Clicky, a real-time, privacy-friendly web analytics service. It overlaps with GA4 in function, so the two are complementary web-analytics feeds into Digital and Marketing rather than independent sources.
- **API:** Clicky Stats API v4. Base `https://api.clicky.com/api/stats/4` (api.getclicky.com also resolves). A separate Account API at `https://api.clicky.com/api/account/sites` returns every site with its site_id and sitekey, useful for automated discovery.
- **Auth:** each request carries the numeric site_id and the sitekey, a 12 to 16 character read key from the site preferences page. There is no login or session.
- **Data:** requested with the type parameter, covering visitors, visitor lists, actions, pages, searches, referrers, countries, goals, and segmentation. Multiple types can be combined in one comma-separated request, which is faster than separate calls. Some types require a premium account.
- **Output:** XML by default; request `output=json` or serialized PHP.
- **Extract:** scheduled pull by date range via the date parameter, landing daily.
- **Governance gotcha:** the sitekey is an API credential passed in the query string. Requests must be HTTPS only, the sitekey must live in Key Vault, and pipeline logging must not capture the full request URL. This is the one place our no-secrets-in-URLs rule bends to a vendor's auth design, so it needs those compensating controls.
- **Landing path:** scheduled Azure Functions pull into Bronze.
- **To confirm:** which metrics Clicky is authoritative for versus GA4, since visitor and session definitions differ between them and ADR-005 will need to assign each metric a single source of truth; and whether the account tier exposes the data types we need.

### 4.11 Identity graph — derived, no external API

- **Source:** internal. Constructed from CRM, ticketing POS, and retail identifiers via email and phone. No external API.
- **What we need:** decide whether it is built in dbt from the other landed feeds or sourced upstream, and once GoFundMe Pro and Marketing Cloud are landed, whether their donors and subscribers should also feed the graph.

---

## 5. The reconciliation design point

Three independent revenue feeds need to tie back to one system of record. Ticketing and retail from Galaxy, online giving from GoFundMe Pro, and Salesforce gifts all post into Financial Edge NXT general ledger. The plan treats the GL as the reconciliation anchor, with a defined match key and tolerance per channel, so the existing revenue reconciliation test extends from a single-source check into a true cross-source control once all four feeds are landed.

---

## 6. Ingestion architecture summary

| Source | Auth | Extract route | Recommended landing into Bronze |
|---|---|---|---|
| Galaxy (ticketing, retail, membership) | SQL login | SQL Server read | Azure Functions copy activity |
| Salesforce CRM | OAuth 2.0 JWT bearer | Bulk API 2.0 incremental | Azure Functions pipeline or connector |
| Marketing Cloud | OAuth 2.0 client credentials | Data Extract to SFTP, or REST | SFTP pickup or API pull |
| GA4 | Service account OAuth 2.0 | BigQuery export or Data API | BQ copy step, or Data API pull |
| Google Ads | OAuth 2.0 plus developer token | GAQL searchStream | API pull or connector |
| Meta Ads | OAuth 2.0 system-user token | Insights edge | API pull or connector |
| GoFundMe Pro | OAuth 2.0 client credentials | REST transactions and campaigns | API pull |
| Vena | HTTP Basic application token | Export API, or Azure Functions integration | Azure Functions integration preferred |
| Financial Edge NXT | OAuth 2.0 plus subscription key | SKY API GL, or Power Platform connector | API pull or connector |
| Wufoo | HTTP Basic API key | REST v3 entries, incremental by DateCreated | Fabric pull, webhooks optional |
| Clicky | site_id plus sitekey in query | Stats API v4, daily by date range | Fabric pull, HTTPS only |

Every credential above lands in Azure Key Vault. No source uses hardcoded secrets.

---

## 7. Proposed sequencing

Sequencing is a proposal; business deadlines may reorder it.

**Phase 0 — harden what is already modeled.**
Tighten freshness on the scan feed, add tests to the identity graph, and add the retail product dimension. These improve trust regardless of source.

**Phase 1 — close the fundraising and finance spine.**
Expand Salesforce to gifts and opportunities, land GoFundMe Pro, and land Financial Edge NXT general ledger. GoFundMe Pro and SKY API are both well-documented OAuth flows, so this is a defined build. This phase unblocks Revenue and Fundraising, Donor Relations, and cross-source reconciliation.

**Phase 2 — planning and variance.**
Land Vena, preferring the prebuilt Azure Functions integration over hand-built Export API pulls.

**Phase 3 — marketing depth.**
Decide GA4 BigQuery export versus Data API, add Marketing Cloud journey objects if needed, and build the paid-media to conversion attribution joins.

---

## 8. Standards every feed must meet

- Lands in the immutable Bronze schema; staging applies the first transformation as `stg_[source]__[entity]`.
- `meta.owner` and `meta.source_system` populated on every staging model.
- Source freshness configured on every Bronze table, mapped to an SLA tier.
- Primary keys carry unique and not_null; categoricals carry accepted_values.
- Credentials in Azure Key Vault only.
- No metric or Gold model built on the feed until its definitions clear the ADR-005 gate.

---

## 9. Inputs needed from you

Resolved in this version: Financial Edge NXT confirmed as the GL product; auth model and extract route now defined per source.

Still open:

1. **Galaxy access:** direct SQL Server read versus a supported Gateway data API, given vendor-support implications.
2. **Retail POS:** Galaxy module or a separate store POS vendor.
3. **Salesforce:** NPSP versus Nonprofit Cloud, and the final object list beyond Contact.
4. **GA4:** BigQuery export versus Data API.
5. **Marketing Cloud:** authoritative subdomain and business unit MID.
6. **Vena:** regional hub host, and whether to use the Azure Functions integration.
7. **Sequencing:** any board reporting or campaign deadline that should pull a source forward.
8. **Wufoo:** which forms are in scope, which domains they feed, and the form owner.
9. **Clicky:** which web metrics it owns versus GA4, and whether the account tier exposes the needed data types.