# ADR-005: Metric Definition Gate

**Status:** Accepted  
**Date:** 2026-04-01  
**Deciders:** Jeremy Myers

## Context

Without a formal approval process, metrics get defined inconsistently across models and reports. Two reports can show different "revenue" figures because each defines it slightly differently.

## Decision

No Gold model may be built until the metrics it exposes have been formally defined and approved by the relevant domain owner. The definition must be documented in `docs/business/METRIC_GLOSSARY.md` before the model is written.

## Process

1. Developer proposes metric definition in a PR to `METRIC_GLOSSARY.md`
2. Domain owner (Sarah Chen / Attendance, Diane Foster / Revenue, Rachel Torres / Membership, etc.) reviews and approves
3. Jeremy Myers approves the PR
4. Gold model build begins

## Consequences

- Slower Gold model development initially
- Eliminates metric inconsistency across reports
- Power BI dashboards always reflect agreed definitions
- New developers have a reference for what every metric means
