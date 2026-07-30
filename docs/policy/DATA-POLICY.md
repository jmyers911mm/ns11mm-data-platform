# Data Governance and Integrity Policy

**National September 11 Memorial & Museum at the World Trade Center**
Version 1.0 · Effective April 2026 · Owned by the VP, AI & Analytics

| Field | Value |
|---|---|
| Version | 1.0 |
| Effective Date | April 2026 |
| Policy Owner | VP, AI & Analytics |
| Approver | Chief Information Officer |
| Next Review | April 2027 |
| Status | Active |

**Document Note:** This policy consolidates and supersedes prior drafts of the Data Integrity and Governance Policy. It should be reviewed in conjunction with the IT Security Policy, Privacy Policy, and Records Retention Schedule. Updates require approval from the Policy Owner and CIO.

## Table of Contents

1. [Purpose](#1-purpose)
2. [Scope](#2-scope)
3. [Roles and Responsibilities](#3-roles-and-responsibilities)
4. [Data Governance Principles](#4-data-governance-principles)
5. [Data Classification Framework](#5-data-classification-framework)
6. [Data Lifecycle Management](#6-data-lifecycle-management)
7. [Data Quality Management](#7-data-quality-management)
8. [Operational Standards for Data Management](#8-operational-standards-for-data-management)
9. [Compliance & Legal Requirements](#9-compliance--legal-requirements)
10. [Governance Cadence & Reporting](#10-governance-cadence--reporting)
11. [Training & Awareness](#11-training--awareness)
12. [AI & Advanced Analytics Governance](#12-ai--advanced-analytics-governance)
13. [Policy Enforcement](#13-policy-enforcement)
14. [Appendix A: Reference Assets & Living Documents](#appendix-a-reference-assets--living-documents)

## 1. Purpose

To ensure accuracy, consistency, security, and accountability in the management of all organizational data at the National September 11 Memorial & Museum (the Museum). This policy governs data collection, storage, use, sharing, and quality across all departments, supporting legal compliance, operational integrity, and the Museum's mission to bear witness and preserve the historical record.

## 2. Scope

This policy applies to:

- **Data types:** visitor records, donor information, archival and historical records, operational metrics, staff data, and digital content.
- **Personnel:** all Museum departments and staff interacting with data, including contractors, external partners, and vendors.
- **Systems:** databases, spreadsheets, cloud storage, analytics platforms (including Snowflake and Power BI), and physical records.

## 3. Roles and Responsibilities

The following roles carry defined data governance responsibilities across the Museum:

| Role | Responsibilities |
|---|---|
| **VP, AI & Analytics** | Owns this policy; oversees data governance strategy; ensures compliance; chairs the governance council. |
| **Data Steward / Analyst** | Ensures data accuracy; validates inputs; monitors integrity; maintains the data dictionary; manages QA processes. |
| **Legal & Compliance** | Reviews data policies for regulatory compliance (privacy, archival, donor laws); advises on data subject rights. |
| **IT / Security** | Protects data integrity; manages access controls; implements backups, encryption, and infrastructure security. |
| **Business Unit Leads** | Ensure proper data use within departments; submit requests for new data access or use cases; champion data quality. |
| **All Staff** | Follow approved data procedures; report anomalies or suspected breaches; complete required governance training. |

**Note:** The AI & Data Committee (referred to in earlier drafts of this policy as the "Data Governance Council"; naming standardized per the 2026-06-19 committee minutes), comprising the VP of AI & Analytics, CIO, Legal, and designated Business Unit Leads, meets quarterly to review policy, data quality metrics, and escalated issues.

## 4. Data Governance Principles

All data practices at the Museum are guided by the following principles:

- **Accuracy:** Data must be correct and consistent across all systems.
- **Completeness:** All required fields and records must be captured without omission.
- **Consistency:** Standardized formats, definitions, and naming conventions for shared data.
- **Security & Privacy:** Access controls, encryption, and adherence to applicable privacy regulations.
- **Accountability:** Clear ownership for each data source, dataset, and record.
- **Auditability:** Maintain logs and documentation of data changes and access.
- **Transparency:** Business users can access relevant data while security and privacy restrictions are respected.
- **Mission Integrity:** Data practices must uphold the dignity and accuracy of the Museum's historical and commemorative record.

## 5. Data Classification Framework

All Museum data must be classified according to one of the following tiers. Classification governs access controls, sharing permissions, and handling requirements throughout the data lifecycle.

| Classification | Description | Museum Examples |
|---|---|---|
| **Public** | Information cleared for unrestricted external sharing. | Museum exhibition descriptions, press releases, public event schedules |
| **Internal** | General operational data; not for external sharing without approval. | Staff directories, internal reports, operational metrics |
| **Confidential** | Sensitive data requiring restricted access and handling controls. | Donor records, vendor contracts, HR data, financial data |
| **Restricted** | Highest sensitivity; legal or mission-critical; tightly controlled. | Victim/family data, PII with legal obligations, archival records with access restrictions |

Data owners are responsible for assigning and maintaining classification labels. Classification must be revisited when data is repurposed or shared with new audiences.

## 6. Data Lifecycle Management

The following standards apply to each stage of the data lifecycle. Museum-specific context is noted where applicable.

### 6.1 Collection

- Validate input at the point of entry using system-level constraints or form validation.
- Use standardized formats for archival, visitor, and donor data.
- Collect only data necessary for operational, legal, or mission purposes (data minimization).
- For archival and commemorative records, follow established provenance and chain-of-custody standards.

### 6.2 Storage

- Use secure databases and physical archives with controlled access.
- Implement role-based access controls (RBAC) aligned to data classification tiers.
- Use encryption at rest and in transit for Confidential and Restricted data.
- Maintain redundancy and disaster recovery procedures for all critical datasets.

### 6.3 Usage

- Access and use data strictly for approved, documented purposes.
- Ensure data accuracy and certification status before using data in reporting or analytics.
- Do not combine or transform datasets in ways that could re-identify anonymized records.

### 6.4 Sharing

- **Internal sharing:** Follow approval workflows and access control procedures.
- **External sharing:** Require legal review and a documented data sharing agreement before sharing with third parties.
- Restrict Restricted-class data (e.g., victim/family data) from external sharing except as required by law or explicit consent.

### 6.5 Retention & Disposal

- Retain data according to regulatory, archival, donor, and operational requirements as defined in the Records Retention Schedule.
- Archival and commemorative records may carry indefinite retention obligations; consult Legal before disposal.
- Dispose of data no longer needed via secure deletion methods; document disposal events.

## 7. Data Quality Management

**Objective:** Ensure all organizational data is accurate, complete, consistent, timely, and reliable, with clear ownership and repeatable processes for validation and issue resolution.

### 7.1 Data Quality Dimensions

All critical datasets must be evaluated against the following dimensions:

| Dimension | Definition | Example Checks |
|---|---|---|
| **Accuracy** | Data correctly reflects real-world values | Donor totals match source system |
| **Completeness** | Required fields are populated | No null values in required fields (e.g., ticket date) |
| **Consistency** | Data is uniform across systems | Same visitor counts across all dashboards |
| **Timeliness** | Data is up-to-date and available when needed | Daily refresh completed by 8 AM |
| **Validity** | Data conforms to defined formats and rules | Valid email formats, date ranges within bounds |
| **Uniqueness** | No unintended duplicates | One record per transaction ID |

### 7.2 Data Quality Rules & Validation Framework

Define data quality rules at three levels:

- **Source-level validation:** input constraints, required fields, format checks at point of entry.
- **Transformation-level validation:** ETL/ELT logic checks ensuring accurate data movement and calculation.
- **Consumption-level validation:** BI/report-level checks confirming outputs match certified datasets.

Implementation standards:

- Use automated testing frameworks (e.g., dbt tests) for null checks, unique constraints, and referential integrity.
- Store all quality rules in a central repository tied to their respective datasets.
- Examples: source required fields cannot be null; revenue totals must reconcile to source system; dashboard totals must match certified datasets.

### 7.3 Data Profiling & Baselining

**Objective:** Establish expected data patterns and detect anomalies early.

- Perform initial data profiling for all new datasets: distribution of values, null rates, min/max ranges.
- Define baseline thresholds (e.g., expected daily visitor count range) for ongoing comparison.
- Continuously compare incoming data against baselines to detect data drift, upstream system issues, or unexpected behavioral changes.

### 7.4 Monitoring & Alerting

**Objective:** Detect and respond to data issues in near real-time.

- Implement automated monitoring for: pipeline failures, data freshness SLAs, volume anomalies, and schema changes.
- Define alert thresholds and severity levels: Critical (pipeline failure, missing data), High (major metric deviation), Medium (minor discrepancies).
- Route alerts to the Data Team (primary) and Business Owners (if impacting reporting).
- All alerts must generate a tracked incident in the central issue log.

### 7.5 Issue Management & Resolution

**Objective:** Ensure consistent handling and documentation of data issues.

Workflow:

- **Detection:** Automated alert or user-reported issue logged in the issue tracking system.
- **Triage:** Assign severity level and responsible owner.
- **Investigation:** Identify root cause (source, transformation, or usage layer).
- **Resolution:** Fix data and/or pipeline; validate the fix.
- **Documentation:** Log issue, root cause, resolution, and any systemic recommendations.

Conduct recurring reviews of the issue log to identify systemic patterns. Track time-to-resolution and root cause categories as governance KPIs.

### 7.6 Reconciliation & Certification

**Objective:** Ensure alignment between systems and establish trusted, certified datasets.

- Perform regular reconciliation checks: source vs. warehouse, warehouse vs. BI reports.
- Certified datasets must be fully validated and approved by data and relevant business stakeholders.
- Only certified datasets should be used for executive reporting, financial reporting, and donor reporting.

### 7.7 Data Quality SLAs & Ownership

- Assign data owners/stewards for each critical dataset with defined responsibilities.
- Define SLAs for data freshness (e.g., daily refresh by 8 AM) and issue response time (e.g., critical issues within 2 hours).
- Track and report on data quality scores and SLA adherence as part of quarterly governance reviews.

### 7.8 Audit & Continuous Improvement

**Objective:** Continuously improve data quality processes.

- Conduct periodic data quality audits reviewing failed tests, recurring issues, and SLA breaches.
- Implement root cause analysis (RCA) and preventative fixes, not only reactive remediation.
- Continuous improvement loop: identify issue, fix, update validation rules, monitor.

## 8. Operational Standards for Data Management

This section governs how the data team develops, maintains, and delivers data assets to the organization.

### 8.1 Reusable Data Assets (Single Source of Truth)

**Objective:** Minimize redundancy and ensure consistency across reporting and analytics.

- Commonly used datasets must be developed as certified, reusable data models (e.g., curated tables, dbt models, semantic layers).
- Reusable assets must have a clearly defined owner, be documented in the data dictionary, and include business logic definitions (e.g., KPI calculations).
- Analysts must use existing certified datasets before creating new ones.
- New reusable assets require documented justification and review/approval by the data team.

Anti-patterns to avoid:

- Rebuilding the same metric in multiple dashboards.
- Hardcoding business logic in BI tools instead of centralized models.
- Creating shadow datasets in spreadsheets outside governed systems.

### 8.2 Limiting One-Off and Duplicate Queries

**Objective:** Reduce fragmentation and conflicting outputs.

- One-off queries must be temporary and not used for recurring reporting.
- Store one-off queries in a shared, searchable repository (e.g., version control or query library).
- If a query is reused more than 2-3 times, it must be converted into a reusable data model or view.
- Duplicate logic identified in multiple places must be consolidated into a single governed asset.

### 8.3 Data Dictionary & Metadata Management

**Objective:** Ensure shared understanding of data definitions across business, legal, and technical teams.

- Maintain a centralized data dictionary accessible to all stakeholders.
- Each dataset and field must include: business definition, technical definition, source system, owner/steward, and data sensitivity classification (Public, Internal, Confidential, Restricted).
- KPIs and metrics must have a single agreed-upon definition with version control and change history.
- Updates to definitions require review from data and relevant business stakeholders, plus communication of downstream impact.

### 8.4 Cross-Training & Knowledge Sharing

**Objective:** Reduce single points of failure and improve team resilience.

- Each critical data domain (e.g., donors, ticketing, archives) must have a primary owner and at least one secondary backup.
- All production pipelines and models must be fully documented.
- Conduct regular knowledge transfer sessions and documentation reviews.
- Encourage shared code repositories and standardized development practices.

### 8.5 QA Process for Data Releases

**Objective:** Ensure accuracy, reliability, and trust in all published data products.

Release types: new datasets/models, changes to existing logic, dashboard/report updates.

QA standards by phase:

- **1. Development QA:** Unit testing of transformations (dbt tests); schema validation; peer code review before merge.
- **2. Data Validation:** Row count comparisons vs. source; aggregate reconciliation (totals, averages, trends); spot checks against known benchmarks.
- **3. Business Validation:** Confirm outputs with business stakeholders; validate KPI definitions and expected behavior.
- **4. Pre-Production Testing:** Test in staging environment; validate permissions and access controls.
- **5. Post-Release Monitoring:** Monitor for anomalies or breaks; establish alerting for data failures.

### 8.6 Change Management & Version Control

**Objective:** Ensure traceability and minimize disruption.

- All data model changes must be tracked in version control with clear descriptions.
- Breaking changes require advance notice to impacted stakeholders and a migration or transition plan.
- Maintain version history of key datasets and KPIs.

### 8.7 Data Access & Usage Controls

**Objective:** Balance accessibility with governance.

- Implement role-based access controls aligned to data classification tiers.
- Prioritize certified datasets in BI tools.
- Clearly label deprecated datasets and remove after a defined sunset period.

### 8.8 Performance & Efficiency Standards

**Objective:** Ensure scalable and cost-efficient data usage.

- Optimize queries and transformations for performance.
- Avoid unnecessary duplication of large datasets.
- Periodically monitor query costs and pipeline runtimes; refactor inefficient models.

## 9. Compliance & Legal Requirements

- Adhere to applicable privacy laws and regulations governing visitor and donor data.
- Protect archival integrity for historical materials in accordance with relevant preservation standards.
- Ensure data subject rights (e.g., access, correction, deletion) are honored where applicable.
- Document data-handling procedures and maintain audit trails for legal defensibility.
- Any data breach or suspected breach must be reported to Legal and IT Security immediately per the Incident Response Plan.

## 10. Governance Cadence & Reporting

The following regular activities sustain active governance:

- **Quarterly:** AI & Data Committee review of data quality metrics, SLA adherence, policy updates, and escalated issues. Attended by VP of AI & Analytics, CIO, Legal, and Business Unit Leads.
- **Monthly:** Data steward review of quality scores, open incidents, and certification status of critical datasets.
- **On-demand:** Incident reporting process for breaches, pipeline failures, or significant data anomalies.
- **Annually:** Full policy review and update cycle; data governance training refresh.

Data quality dashboards will be maintained and accessible to business units, reflecting current quality scores, SLA adherence, and open incident counts.

## 11. Training & Awareness

- Mandatory data governance training is required for all staff who create, access, or use organizational data.
- Onboarding training must be completed within 30 days of hire for all applicable roles.
- Annual refresher training required for all staff; more frequent updates for data team members.
- Policy changes and new regulatory requirements must be communicated promptly with updated guidance.
- Clear guidelines and SOPs for routine data tasks will be maintained in the SharePoint library.

## 12. AI & Advanced Analytics Governance

As the Museum expands its use of AI-powered analytics and automation, the following standards apply to all AI and machine learning initiatives involving Museum data.

### 12.1 Permitted Use

- AI and advanced analytics tools may be used to derive insight from operational, visitor, archival, and donor data where there is a documented, approved use case.
- AI must not be used to make autonomous decisions affecting individuals (e.g., donor outreach, access to services) without human review.
- Any AI use involving archival content, victim/family records, or commemorative materials requires explicit approval from the VP of AI & Analytics, Legal, and senior leadership.

### 12.2 Data Inputs & Model Documentation

- All AI models must document: data inputs used, training methodology, intended use, known limitations, and responsible owner.
- Only certified datasets may be used as inputs to production AI models.
- Prohibited: using Restricted-class data (e.g., victim/family records) as model training inputs without explicit legal clearance.

### 12.3 Human-in-the-Loop Requirements

- AI outputs used in external communications, public-facing content, or donor engagement must be reviewed and approved by a qualified staff member before use.
- AI-generated content referencing the September 11 attacks, victims, or historical events must be reviewed by subject matter experts for accuracy and appropriateness.

### 12.4 Vendor & Third-Party AI Tools

- Any third-party AI tool that processes Museum data must be reviewed and approved by IT Security and Legal.
- Data sharing with AI vendors must comply with Section 6.4 (Sharing) and include data processing agreements.
- AI vendor tools may not be used to train external models on the Museum's Confidential or Restricted data.

## 13. Policy Enforcement

Violations of this data governance policy may result in:

- Mandatory retraining and additional oversight requirements.
- Access restrictions or revocation of data privileges.
- Escalation to HR or Legal, up to and including disciplinary action.

This policy is reviewed and updated annually by the AI & Data Committee, with approval from the Policy Owner (VP, AI & Analytics) and the CIO. All updates are version-controlled and communicated organization-wide.

## Appendix A: Reference Assets & Living Documents

The following assets support day-to-day implementation of this policy. Owners are responsible for keeping them current.

| Asset | Description | Location / Owner |
|---|---|---|
| **Data Dictionary** | Centralized repository of all dataset and field definitions | SharePoint |
| **Certified Datasets Register** | List of approved, validated datasets for reporting use | Data Team, updated quarterly |
| **Issue Log / Ticketing** | Central log for all data quality incidents and resolutions | Trello / IT ticketing system |
| **QA Checklist** | Pre-release checklist for new datasets and dashboard updates | Data Team SharePoint |
| **Training Materials** | Data governance onboarding and refresher resources | SharePoint Learning Library |
| **Related Policies** | IT Security Policy, Privacy Policy, Records Retention Schedule | Legal / IT SharePoint |

*End of Policy*