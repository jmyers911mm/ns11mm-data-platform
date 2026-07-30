# Start Here — NS11MM Data Platform (for business users)

Welcome. This page is written for everyone **outside** the data team — Development, Membership, Marketing, Operations, Education, and Finance. No technical background needed.

If you've ever asked *"how many people visited last weekend?"*, *"how is the spring campaign performing?"*, or *"are we retaining members?"* — the answers live here, and this page tells you exactly where to find them.

> **What's available today (July 2026):** the platform is being built in stages. Live today:
> **Revenue and Operations via the Daily Performance Report** — daily tickets, tours, retail,
> donations, and fees from our ticketing (Gateway) and retail (CounterPoint) systems — and the
> **Retail Performance** dashboard built on the retail estate. The other areas below
> (Membership, Donor Relations, Digital/Marketing, and the attendance/capacity views) are
> **planned** and arrive as each source system is connected.
> Rows marked *(planned)* below are not available yet.

---

## What this platform is, in one paragraph

The NS11MM Data Platform brings together information from our ticketing, retail, donor, membership, and email systems into **one trusted place**. Instead of pulling separate reports from each system (and getting numbers that don't match), everyone now works from the same, consistent set of numbers — refreshed automatically every day. The dashboards you use are all built on top of this single foundation, so "member" or "visitor" or "revenue" means the same thing no matter which report you open.

---

## What questions can it answer?

The platform is organized into six areas. Each area has certified metric *definitions*; the
dashboards behind them are being delivered in stages (see status note above). **Revenue and
Operations** is live today via the Daily Performance Report; the rest are planned.

| Area | Example questions it answers |
| --- | --- |
| **Attendance and Visitation** | How many people visited? When are our busiest hours and gates? How full are we against capacity? |
| **Revenue and Fundraising** | What did we earn from tickets, retail, and donations? What's the average transaction? How are we tracking against budget? |
| **Membership** | How many active members do we have? Who's lapsing? What's a member worth over time? |
| **Donor Relations** | Are we retaining donors? Which cohorts are at risk of churning? Who's ready to upgrade? |
| **Digital and Marketing** | How did the last email campaign perform — opens, clicks, unsubscribes? Which channels are driving visitors? |
| **Operations** | What does a typical day or month look like across all revenue streams? |

---

## Find your dashboard

Match your question to the dashboard that answers it. If you don't have access, see [How to get access](#how-to-get-access) below.

| Your question | Dashboard | Status | Best for |
| --- | --- | --- | --- |
| "How did today/this month go across tickets, tours, retail, and donations?" | **Daily Performance Report** | **Live** | Operations, Finance, leadership |
| "How did today/this week go across tickets, retail, and visitors?" | Daily Operations | *(planned)* | Operations, leadership |
| "Where and when are visitors coming in? Are we near capacity?" | Capacity Planning | *(planned)* | Operations, Visitor Experience |
| "How are members and donors trending? Who's lapsing or at risk?" | Membership and Donors | *(planned)* | Membership, Development |
| "How is the gift shop performing?" | **Retail Performance** | **Live** | Operations, Retail |
| "How is our email marketing performing?" | Campaign Performance | *(planned)* | Marketing |
| "What's a visitor worth over their lifetime?" | Customer LTV | *(planned)* | Development, Membership |
| "How are paid and organic channels driving revenue?" | Digital Marketing | *(planned)* | Marketing, Digital |

---

## What every number means

Every metric used in dashboards is certified before it ships. The authoritative definitions live in the semantic view specs in [`cortex_project/`](../../cortex_project/) (the same definitions that power self-service AI querying); the governance rules for how metrics are defined and changed are in [Building Reports & Metrics](../architecture/BUILD_DIMS_METS.md). If you ever see a number and wonder exactly how it's calculated, start there — or just ask Jeremy.

A few of the most common ones:

| Metric | Plain-English definition |
| --- | --- |
| **Total Visitors** | Count of individual ticket scans at any gate on a given day |
| **Ticket Revenue** | Sum of ticket transaction amounts (gross, before discounts) |
| **Active Members** | Members with status = Active as of the report date |
| **Donor Retention Rate** | Donors who gave in both the current and prior year, as a percentage of prior-year donors |
| **Open Rate** | Percentage of sent emails that were opened at least once |
| **September 11 Flag** | Metrics on September 11 are flagged separately — the anniversary creates structural anomalies across attendance, revenue, and retail that should not be treated as a statistical outlier |

---

## How to get access

To request access to a Power BI dashboard:

1. Contact Jeremy Myers (VP of AI & Analytics) or your department head
2. Specify which dashboard(s) you need and why
3. Access is granted within one business day for standard dashboards

For self-service analytics access (running your own queries against the data), contact Jeremy — this requires an Analyst Role account in Snowflake.

---

## Who to ask

| Question type | Contact |
| --- | --- |
| Dashboard access or Power BI issues | Jeremy Myers (platform owner) |
| What a metric means | [Building Reports & Metrics](../architecture/BUILD_DIMS_METS.md) and the `cortex_project/` semantic views first, then Jeremy Myers |
| Something looks wrong in the numbers | Jeremy Myers — include the dashboard name and the specific number |
| New report or analysis request | Jeremy Myers — submit through the Platform Hub |
| Attendance or ticketing data | Chris Wogas (Attendance & Ticketing) |
| Fundraising data | Jan-Michael Llanes (Fundraising) |
| Retail data | Gennady Zaritsky (Retail) |
