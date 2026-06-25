# ADR-008: Retail Source Split (CounterPoint vs Shopify)

**Status:** Proposed — Decision Required  
**Date:** 2026-06-23  
**Deciders:** Jeremy Myers + Retail operations

## Context

NS11MM has two retail systems:
- **NCR CounterPoint** — in-museum physical POS
- **Shopify** — e-commerce / online store

Both land to separate RAW tables. The staging and Silver layer must handle them as separate sources. The question is whether Gold facts should merge them into a unified retail fact or maintain them as separate fact tables.

## Options

**Option A: Unified fct_retail_line_items**
Merge CounterPoint and Shopify into one fact table with a `channel` dimension (In-Person / Online). Simpler for reporting.

**Option B: Separate fct_retail_inperson and fct_retail_online**
Maintain separation throughout. More flexibility; more models to maintain.

## Recommendation

Option A — unified with channel flag. Consistent with dim_customer identity resolution pattern.

## Decision Required

☐ Option A — Unified  
☐ Option B — Separate
