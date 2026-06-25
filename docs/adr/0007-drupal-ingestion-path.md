# ADR-007: Drupal CMS Ingestion Path

**Status:** Proposed — Decision Required  
**Date:** 2026-06-23  
**Deciders:** Jeremy Myers + Anna Kim (Digital) + Kenny (IT)

## Context

Drupal content needs to be ingested into the data platform. Two paths are available:

**Option A: Direct database query via self-hosted agent**
- Connects directly to Drupal's MySQL/PostgreSQL backend
- Gives access to all content and metadata
- Requires internal network agent (same pattern as Gateway/CounterPoint)
- Risk: schema dependency on Drupal's internal DB structure

**Option B: Drupal JSON:API**
- REST API that exposes structured content by type
- Cleaner, version-stable interface
- May not expose all metadata needed
- Requires Drupal API user account and token

## Decision Required

☐ Option A — Direct DB  
☐ Option B — JSON:API

## Impact

Decision determines: which secrets go in Key Vault, whether an agent VM is needed, and the pipeline.py implementation in `pipelines/drupal/`.
