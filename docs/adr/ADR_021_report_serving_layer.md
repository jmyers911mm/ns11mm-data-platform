# ADR-021: Report Serving Models Are Named by Role, and Projection Chains Off a Wrapper Are Permitted

- **Status:** Proposed
- **Date:** August 10, 2026
- **Deciders:** Jeremy Myers (VP AI & Analytics)
- **Sharpens:** ADR-018 (Metric Definition Ownership) — supersedes its 2026-07-29 amendment
- **Related:** ADR-004 (No logic in Power BI), ADR-005 (Metric Gate), ADR-020 (Materialization Policy)

---

## Context

Between 2026-07-29 and 2026-08-10 the platform migrated fourteen Pentaho reports onto
Snowflake serving models. `models/marts/reports/` grew from roughly twenty files to
**fifty-four**, its `schema.yml` to **997 lines**, and a set of model *roles* emerged by
repetition rather than by design: a semantic-view wrapper, a budget or prior-year conform, a
period-window definition, one of three serving shapes, and a three-step narrative chain.
Nothing writes those roles down. A seventh report will invent an eighth variant.

Two forcing conditions make this urgent rather than cosmetic.

**ADR-018 and the code now disagree on the flagship pattern.** ADR-018 §3 states plainly that
`rpt_` models must not select from other `rpt_` models. Its 2026-07-29 amendment carved out an
exemption, but did so by *enumerating six filenames*
(`rpt_dpr_narrative_brief`, `rpt_retail_narrative_brief`, `rpt_dpr_report_long`,
`rpt_retail_report_long`, and the two disabled narrative models). Since then the chains have
grown to roughly **twenty** models across seven families — `*_period_windows`, `*_periods`,
`*_print`, `*_narrative_card`, `*_retail_conform`, `*_mtd_ytd_long`, `*_excel_export` — none of
which the amendment names. Every one of those model headers currently claims a "sanctioned
projection-chain exception" on the strength of an amendment that neither covers them nor has
been ratified. The 2026-07-31 release-readiness review flagged exactly this: *"the governance
doc and the code disagree on your flagship pattern."* An enumerated carve-out goes stale the
moment the next report ships; it has already gone stale twice.

**DirectQuery moved presentation work into dbt.** The Daily Tracker and Retail Performance
reports were built in DirectQuery so the report never races the nightly load. DirectQuery
forbids the DAX patterns the original specs assumed — calculated columns computing week
buckets, `FORMAT`/`SWITCH` text measures assembling row labels. That logic had to move
somewhere, and under ADR-004 the only permitted destination is dbt. So the platform now holds
things that are unmistakably *presentation*: rolling week-bucket labels, printed-row catalogs
with padded sort labels, pre-rendered fixed-width analyst cards. ADR-018 §3 says an `rpt_`
model "introduces no new aggregation math." Period-window models sum governed measures across
date windows. Whether that is *exposure at a different grain* (permitted) or *new aggregation
math* (prohibited) is currently a matter of whoever is reading the ADR.

What is not yet known: whether the canonical metric catalogue of ADR-018 §5 arrives before or
after the December 2026 go-live. If it arrives first, several rules here become machine-enforced
rather than review-enforced.

Deadline context: the Pentaho license lapses **January 5, 2027**, production go-live targets
December 2026, and **September 6–16** is a hard change freeze. A restructure of fifty-four
report models is affordable in August and is not affordable in November.

---

## Decision

**1.** Every report serving model takes one of seven named **roles**, and its role determines
what it is permitted to contain. The role is identified by a name suffix.

**2.** `models/marts/reports/` is organised into one subdirectory per **report family**, each
with its own `schema.yml`. Report-layout dimensions and seeds move next to the family they
serve.

**3.** ADR-018 §3's prohibition on `rpt_`-from-`rpt_` is replaced by a **role-based** rule:
a serving model may read another serving model when the reader's role is downstream of the
readee's role in the chain below. This supersedes the 2026-07-29 enumerated amendment.

### The seven roles

| Suffix | Role | May contain | Must not contain |
|---|---|---|---|
| `*_powerbi` | **Wrapper.** The only permitted caller of `SEMANTIC_VIEW()`. One row per report grain. | Dimension and metric projection; nothing else | Any expression beyond aliasing |
| `*_budget_daily`, `*_conform` | **Comparison conform.** Aligns the budget, prior-year, or cross-domain side to the wrapper's column names so both unpivot identically. | Renaming, typed NULL placeholders, cross-domain joins | New metric derivation |
| `*_period_windows` | **Period definition.** The printed period columns as `[start_date .. end_date]` ranges, authored once per report family. | Anchor resolution, window arithmetic | Any measure |
| `*_report_long`, `*_periods`, `*_category_periods`, `*_mtd_ytd_long` | **Serving shape.** Tidy or period-resolved grids. Re-aggregates governed measures at the display grain. | Unpivoting; `SUM` of governed measures over a window; ratio-of-sums from carried numerator/denominator | A pre-divided ratio; a population filter that changes what a metric counts |
| `*_print`, `*_excel_export` | **Presentation shape.** Printed-row or flat-export grids that match a legacy artifact row-for-row and column-for-column. | Row catalogs, label text, print order, scenario selection, typed NULL placeholder columns | Any aggregation not already performed by the serving shape it reads |
| `*_narrative_brief` | **Deterministic brief.** One JSON object per date of every fact a narrative may reference. | Deltas, rankings, trend flags, window sums | An LLM call |
| `*_narrative`, `*_narrative_card` | **Narrative render.** `*_narrative` is the gated Cortex call (`enabled=false`); `*_narrative_card` is the deterministic SQL-rendered card. | `AI_COMPLETE` / `CORTEX.COMPLETE`; string formatting | Any number not present in the brief |

### The permitted chain

```
semantic view
   └── *_powerbi ──┬── *_report_long / *_periods ── *_print
                   ├── *_period_windows ───────────┘
                   ├── *_narrative_brief ── *_narrative / *_narrative_card
                   └── *_excel_export
   *_budget_daily / *_conform ── (joins into the shapes above)
```

A model may read only *leftward* in this chain. A wrapper reading a serving shape, or a brief
reading a print model, is a defect.

### Ratio rule (restated, because it is the one that silently produces wrong numbers)

Non-additive measures are never stored pre-divided. A serving shape carries the numerator and
denominator; the division happens once, at the grain being displayed. This holds whether the
division happens in DAX (Import-mode reports) or in SQL (DirectQuery reports) — what is
prohibited is dividing early and re-aggregating the quotient.

### Composites

A composite (a total that sums other measures) is authored **once**. Preferred home, in order:
a semantic-view metric; failing that, a column on the wrapper; failing that, one serving model
that every consumer reads. Authoring the same composite in two models is a defect even when
both are arithmetically identical today.

### Placeholder columns

A column that exists in the legacy artifact but has no source in the platform is emitted as a
**typed NULL with a comment stating why** — never omitted, never zero-filled, never guessed.
Three causes must be distinguished in the comment: *blocked on a business rule*, *pending an
upstream addition*, *no data feed*. Row-level equivalents carry `availability = 'Stub'` in the
layout catalog.

### Directory structure

```
models/marts/reports/<family>/     one of: dpr, retail, tracker, attendance,
                                   scan, today_sales, website_commerce, restricted
    rpt_<family>_*.sql
    dim_<family>_*line*.sql        layout catalogs, co-located
    schema.yml                     per family
seeds/report_layout/               *_line_items.csv, *_print_lines.csv
```

Families are report clusters, not domains: `tracker` is separate from `dpr` though it reads the
DPR wrapper, because it is a distinct printed artifact with its own layout catalog.

---

## Options considered

### Option A: Role-based rule plus family directories (selected)

Roles are declared once and identified by suffix; the chain defines legal reads; directories
follow report families. New reports inherit the grammar by naming their models correctly, and a
reviewer checks role compliance rather than recalling a filename list.

It wins on three counts. It cannot go stale the way an enumerated list does — a new
`rpt_membership_report_long` is covered the day it is written, with no ADR amendment. It makes
review mechanical: the suffix tells you which rules apply. And it is enforceable by automation
later (a CI check can assert that every `rpt_*_powerbi` is the only `SEMANTIC_VIEW()` caller and
that no model reads rightward in the chain), which an enumerated list cannot be.

### Option B: Keep the enumerated exemption, extend it each release (set aside)

Its genuine advantage is precision: an enumerated list is unambiguous about exactly which models
are exempt, leaves no room for a developer to argue their new model "is basically a projection,"
and requires no new abstraction to understand. For a platform that had stopped growing, it would
be the lower-risk choice.

Set aside because the list has already fallen out of date twice in twelve days, and the failure
mode is bad: model headers claim a sanction the governance document does not actually grant,
which is worse than having no exemption at all. Ten more reports across four more domains are
expected before go-live.

### Option C: Rewire so no `rpt_` reads another `rpt_` (set aside)

The orthodox reading of ADR-018 §3. Each serving model would read facts and dimensions directly.
Its real merit is that the dependency graph becomes shallow and every model is independently
comprehensible — a genuine benefit for onboarding, and it eliminates the "fix `rpt_dpr` and
break three reports" failure that §3 was written to prevent.

Set aside because it forces exactly the duplication ADR-018 exists to prevent. Without the
wrapper chain, the `SEMANTIC_VIEW()` projection, the earned-revenue composite, and the period
windows would each be retyped in five to eight models. The 7.12.1 release found a live instance
of this cost: the earned-revenue composite existed in three places and two of them disagreed
(one coalesced NULL components, one did not, so a single missing feed blanked an entire printed
line). Shallow graphs traded for duplicated logic is the wrong trade for this platform.

### Option D: Flat directory, split `schema.yml` only (set aside)

Address the 997-line YAML file without moving any `.sql`. Genuinely the lowest-risk option: no
file moves at all, so nothing can break, and it fixes the single worst pain point.

Set aside because it leaves a report build touching three directories (`reports/`,
`dimensions/`, `seeds/`) and leaves fifty-four files in one listing. It remains the fallback if
the migration in §2 hits trouble — the schema split is independently valuable and can ship alone.

---

## Consequences

**Positive**

- New reports inherit the pattern from their model names; no ADR amendment per report.
- The 997-line `schema.yml` becomes eight files of roughly 120 lines, so a PR touching one report
  stops colliding with every other report's documentation.
- A report build touches one directory instead of three.
- Role compliance is CI-checkable later: one caller of `SEMANTIC_VIEW()` per family, no rightward
  reads, no pre-divided ratios in a serving shape.
- Records, for the first time, that presentation formatting in dbt is *intentional* under
  DirectQuery rather than a drift from ADR-004.
- Path-based selection becomes available (`dbt build --select models/marts/reports/retail`).

**Negative**

- A one-time move of roughly seventy files. `ref()` is name-based so references survive, but
  every model's YAML block must move with it, and an incomplete move produces undocumented-model
  warnings rather than a hard failure — so it can pass CI while being wrong.
- Report-layout dimensions leave `models/marts/dimensions/`, so "all dimensions live in
  `dimensions/`" stops being true. A future reader must learn the business-versus-layout
  distinction. This was a genuine coin flip; co-location won on build ergonomics, not on
  conceptual purity.
- Moving layout dims from the `gold_dimensions` group to `gold_reports` changes their dbt group.
  All are `access: public`, so nothing breaks today, but a future `private` access rule would
  need to account for it.
- Seven suffixes is more vocabulary than "one report, one model." Reviewers must learn it.
- The `*_print` role legitimises a deliberate hack: `line_item_display` pads repeated labels with
  occurrence-index trailing spaces so Power BI's sort-by-column (which requires a 1:1
  label-to-sort mapping) accepts them. It is invisible in rendering and load-bearing in the
  model. A well-intentioned cleanup would silently break row order.

**Accepted risks**

- **Presentation logic in the warehouse ages differently than logic in the report.** A rendered
  ASCII card and a padded sort label are coupled to one consumer's quirks. If the reports move
  off Power BI or off DirectQuery, these models become dead weight rather than assets. Accepted
  because ADR-004 leaves no alternative destination and DirectQuery was chosen deliberately.
- **Three composites are currently authored in `rpt_dpr_mtd_ytd_long`, not in the semantic view**
  (`TOTAL_GUIDED_TOUR_REVENUE`, `TOTAL_OTHER_VISITOR_REVENUE`, `TOTAL_ESTIMATED_REVENUE`). This
  is the weakest form permitted by the composites rule above. Mitigating factor: all three were
  verified to the cent against the 2025-12-31 MTD *and* YTD workbooks, so the definitions are
  evidenced rather than assumed. They should be promoted to semantic-view metrics.
- **`TOTAL_ESTIMATED_REVENUE` is presently authored twice** — in `rpt_dpr_mtd_ytd_long` and
  inline in `rpt_dpr_report_long`. This violates the composites rule on the day the ADR is
  written. It is recorded here rather than hidden, with remediation owed in the next release.
- **§3 requires committee ratification.** Until then, model headers should cite ADR-021 as
  *Proposed*. Twenty models depend on a rule that is not yet ratified — the same exposure the
  2026-07-29 amendment carried, now at least written down accurately.
- Two reports of the fourteen are not yet inventoried, so the family list may gain a member.

---

## Revisit trigger

Reopen when **any** of these occurs:

1. **The ADR-018 §5 canonical metric catalogue ships.** Semantic views and serving models become
   generated artifacts, at which point the role rules are enforced by the generator and the
   suffix grammar may be redundant.
2. **A report family stops being served by Power BI, or moves off DirectQuery to Import.** The
   `*_print`, `*_periods`, and `*_narrative_card` roles exist because of DirectQuery's
   restrictions; if that constraint lifts, presentation logic should move back out of the
   warehouse and those roles should be retired rather than maintained.
3. **A family exceeds roughly fifteen models**, at which point one directory per family is the
   same problem one directory for all reports is today, and sub-grouping by role within a family
   should be considered.
4. **The 007/008 register collision is resolved** (owner: Jeremy) — this ADR cross-references
   ADR-018, and the numbering reconciliation is a good moment to confirm all cross-references in
   the serving-layer documentation resolve to the intended sequence.
