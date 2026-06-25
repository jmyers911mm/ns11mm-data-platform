# Metric Glossary

Plain-English definitions for every certified metric and key term on the Museum Data Platform. This is the **tie-breaker**: if two numbers disagree, the definition here is the source of truth.

Each metric shows what it means, roughly how it's calculated (no code), and where you'll see it. The technical, code-level definitions live in the dbt project; the authoritative business catalog (with owners and approval dates) lives in the Hub's **Metric Registry**.

> **One definition, everywhere.** Every metric here has been approved before being built (see ADR-005). If you need a metric that isn't listed, see ["I need a new metric"](README.md#i-need-a-new-metric-or-report) on the Start Here page.

---

## Key terms (read these first)

These terms appear across many metrics, so they're defined once here.

| Term | What it means |
| --- | --- |

| **Fiscal year / quarter** | Our financial calendar starts in **October**, not January. "FY26" runs October 2025–September 2026. Every dashboard with a fiscal view uses this. |
>>>>>>> remote
| **Customer (resolved)** | One real person, even if they appear in several systems. We link records that share an email **or** phone number, so a single visitor isn't counted three times. |
| **Known Member** | A resolved customer who matches a record in our CRM (Salesforce). We know who they are. |
| **Identified Visitor** | A resolved customer we can recognize by email or phone, but who isn't in the CRM. |
| **Anonymous** | A transaction with no email or phone captured (e.g., a cash sale). Counted in revenue and attendance, but can't be tied to a person. |
| **Membership status** | One of: **Active**, **Grace Period** (recently expired, still in renewal window), **Expired**, or **Lapsed** (long expired). |
| **Donor tier** | One of: **Major**, **Mid-Level**, **Donor**, **Small**, or **Non-Donor**, based on giving level. |
| **Lifetime Value (LTV) tier** | One of: **Platinum**, **Gold**, **Silver**, **Bronze**, based on total value across tickets, retail, and donations. |

---

## Attendance & Visitation

| Metric | What it means | How it's calculated (plain) | Where to find it |
| --- | --- | --- | --- |
| **Total visitors** | Number of people admitted through the gates. | Count of valid entry scans for the day. | Daily Operations, Capacity Planning |
| **Valid scan rate** | Share of gate scans that were legitimate admissions. | Valid scans ÷ all scans, as a percentage. | Capacity Planning |
| **Visitors by hour / gate** | When and where people enter. | Visitors admitted grouped by hour and gate. | Capacity Planning |
| **Capacity utilization** | How full we are versus what we can hold. | Reservations or admissions ÷ available capacity for that time slot. | Capacity Planning |
| **Demand level** | A simple label (e.g., low/normal/high) for how busy a slot is. | Utilization compared against rolling historical benchmarks. | Capacity Planning |

---

## Revenue & Fundraising

| Metric | What it means | How it's calculated (plain) | Where to find it |
| --- | --- | --- | --- |
| **Total revenue** | All money taken in for the period. | Ticket revenue + retail revenue (+ donations where applicable). | Daily Operations |
| **Ticket revenue** | Money from admissions. | Sum of ticket sales, net of discounts. | Daily Operations |
| **Retail revenue (gross / net)** | Gift-shop sales before and after discounts. | Gross = list price × quantity; Net = gross − discounts. | Retail Performance |
| **Average order value (AOV)** | Typical spend per transaction. | Revenue ÷ number of transactions. | Daily Operations, Retail Performance |
| **Revenue per visitor** | How much each visitor is worth on average. | Total revenue ÷ total visitors. | Daily Operations |
| **Discount rate** | How much of retail value is given away in discounts. | Total discounts ÷ gross retail revenue. | Retail Performance |

---

## Membership

| Metric | What it means | How it's calculated (plain) | Where to find it |
| --- | --- | --- | --- |
| **Active members** | Members whose membership is currently valid. | Count of contacts with membership status = Active. | Membership & Donors |
| **Members lapsing / in grace** | Members at risk of being lost. | Count of contacts in Grace Period or recently Expired. | Membership & Donors |
| **Member 360 profile** | A single, unified view of a member's tickets, retail, donations, and email engagement. | Combines all of a resolved customer's activity into one record. | Membership & Donors |
| **Member churn risk** | A flag for members likely to lapse. | Based on time since last interaction and email engagement. | Membership & Donors (predictive) |

---

## Donor Relations

| Metric | What it means | How it's calculated (plain) | Where to find it |
| --- | --- | --- | --- |
| **Retention rate** | Share of a donor group still giving after a period. | Donors still active ÷ donors in the original group (cohort). | Membership & Donors |
| **Churn rate** | Share of a donor group that stopped giving. | 100% − retention rate. | Membership & Donors |
| **Cohort survival** | How long groups of donors keep giving over time. | Tracks each start-month group's retention month over month. | Membership & Donors |
| **Donor upgrade propensity** | How likely a donor is to move up a tier. | Based on giving velocity, gap to next tier, engagement, and tenure. | Membership & Donors (predictive) |
| **Customer LTV** | Total value of a person across tickets, retail, and donations. | Sum of all spend and giving, assigned to a Platinum/Gold/Silver/Bronze tier. | Membership & Donors |

---

## Digital & Marketing

| Metric | What it means | How it's calculated (plain) | Where to find it |
| --- | --- | --- | --- |
| **Open rate** | Share of recipients who opened the email. | Opens ÷ delivered. | Campaign Analytics |
| **Click-through rate (CTR / CTO)** | Share who clicked a link. | Clicks ÷ delivered (or ÷ opens for click-to-open). | Campaign Analytics |
| **Bounce rate** | Share of emails that couldn't be delivered. | Bounces ÷ sent. | Campaign Analytics |
| **Unsubscribe rate** | Share who opted out. | Unsubscribes ÷ delivered. | Campaign Analytics |
| **Unique recipients** | How many distinct people a campaign reached. | Distinct count of people sent to. | Campaign Analytics |

---

## Operations

| Metric | What it means | How it's calculated (plain) | Where to find it |
| --- | --- | --- | --- |
| **Daily operations summary** | One row per day pulling together visitors, ticket revenue, retail revenue, discounts, and scans. | Aggregated across all revenue and attendance streams for the day. | Daily Operations |
| **Monthly operations summary** | The same, rolled up by fiscal month, with peak-day and per-visitor figures. | Monthly aggregation of the daily summary. | Daily Operations |
| **Gates active** | How many entrances were in use. | Count of gates with at least one valid scan. | Daily Operations, Capacity Planning |

---

## Revenue Bridge

| Metric | What it means | How it's calculated (plain) | Where to find it |
| --- | --- | --- | --- |
| **YoY total variance** | How much more (or less) revenue we earned this week versus the same week last year. | This week's gross revenue − same ISO week last year's gross revenue. | Revenue Bridge |
| **YoY ticket / retail variance** | Breakdown of the year-over-year change by revenue stream. | Per-stream revenue this week − same stream same week last year. | Revenue Bridge |
| **Budget vs actual variance** | How actual revenue compares to the plan (trailing 4-week average proxy). | Actual gross revenue − trailing 4-week average. | Revenue Bridge |
| **Budget variance %** | Percentage over/under plan. | (Actual − budget) ÷ budget × 100. | Revenue Bridge |
| **WoW total variance** | Week-over-week revenue change. | This week's gross revenue − prior week's gross revenue. | Revenue Bridge |
| **Ticket / retail discount impact** | How discount changes drove the year-over-year revenue variance. | Change in discount amounts between this year and last year (inverted so positive = less discounting). | Revenue Bridge |
| **Volume change (tickets / retail)** | How transaction volume drove the revenue change. | Tickets sold (or items sold) this week − same metric same week last year. | Revenue Bridge |
| **Revenue per visitor** | Average revenue generated per admitted visitor for the week. | Total weekly gross revenue ÷ total weekly visitors. | Revenue Bridge |

---

## A note on "certified" vs. ad-hoc numbers

- Numbers on the dashboards above and the natural-language assistant are **certified** — they use these approved definitions.
- Numbers you calculate yourself in a spreadsheet are **not** certified and may differ. When they do, the certified definition wins.
- The natural-language assistant only answers using certified definitions (called Verified Queries), which is why it's trustworthy for decision-making.

For the complete, owner-and-approval-date catalog, see the **Metric Registry** in the Platform Hub. For how all of this fits together, see the [Documentation Map](../README.md).
