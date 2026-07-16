# AI & Data Governance Charter

**National September 11 Memorial & Museum**

**Status:** Draft for Committee Review  ·  **Version:** 0.1  ·  **Date:** May 2026  ·  **Owner:** VP, AI & Analytics

> *This document is a working draft, prepared to give the AI & Data Committee a concrete starting point for discussion. The seven principles below represent the foundational commitments we believe should govern all data and AI activity at NS11MM. The characteristics under each principle are proposed, not finalized. Every line here is open for committee review, challenge, and refinement.*

## I. Purpose

The National September 11 Memorial & Museum bears a responsibility that
few institutions share: to bear permanent, faithful witness to the
events of September 11, 2001, and to the lives of all those affected.
This charter exists because the data we collect, the systems we build,
and the artificial intelligence we use in pursuit of that mission carry
real consequences: for the trust of our visitors and donors, for the
integrity of our reporting, and for the reputation of the institution
itself.

This is not a technology document. It is a governance document: a
statement of the values, principles, and structures under which NS11MM
will manage data and AI as organizational capabilities. The operational
policies, platform standards, and tool-specific controls that implement
these commitments are documented separately. This charter is where they
draw their authority.

This charter is owned by the VP of AI & Analytics, sponsored by the
Chief Information Officer, and ratified by the AI & Data Committee. It
applies to all staff, contractors, and vendors who touch NS11MM data or
use AI tools in the course of their work.

**Charter and Policy.** This charter is the "why" and the "what." A
companion Data & AI Policy document, to be developed and ratified
following this charter's adoption, will be the "how." The policy will
translate each principle in this charter into concrete operational
rules: specific access controls, approved tool lists, metric definition
procedures, incident response thresholds, and AI risk classifications.
That level of operational detail belongs in a policy, not a charter,
because it changes more frequently. When platform capabilities evolve,
new tools are adopted, or lessons from incidents reshape our approach,
the policy is updated through a lighter governance process. The
charter's principles, by contrast, should be durable enough that they
rarely need revision, and when they do, that revision requires full
council ratification. Nothing in the policy may conflict with the
charter; where tension exists, the charter governs.

## II. Scope

This charter governs:

- All data collected, stored, processed, or distributed by NS11MM,
    regardless of system or format

- All technology systems, source systems, and reporting tools, that
    ingest, transform, or expose that data

- All uses of artificial intelligence by NS11MM staff, whether as
    individual productivity tools, embedded vendor capabilities, or
    purpose-built analytical systems

- All third parties who access NS11MM data or operate AI systems on
    the organization's behalf

It does not govern the content decisions of curatorial, educational, or
communications staff except where those decisions involve the collection
or use of personal data, or the use of AI to generate content associated
with the Museum's mission or public communications.

## III. Governing Principles

Seven principles govern data and AI at NS11MM. Each states a commitment
and the core characteristics through which that commitment is expressed
in practice. These characteristics are the basis for all downstream
policy; if a policy cannot be traced to one of these principles, its
place in the governance framework should be questioned.

### 1. The mission comes first.

*Data and AI capabilities exist in service of the Museum's mission.
They are means, never ends.*

- **Platform investment is evaluated against mission impact.** A new
    data pipeline, AI tool, or analytics capability earns its place by
    the contribution it makes to attendance, education, donor
    stewardship, or institutional sustainability, not by technical
    sophistication alone.

- **The 25th Anniversary is a concrete readiness milestone.** The
    governance structures must be fully implemented well in advance of
    September 11, 2026. No capability introduced after that date should
    undermine confidence in the data that supports the event.

- **Education program data carries the same rigor as revenue data.**
    The instinct to prioritize financial and operational metrics over
    programmatic ones is understandable but wrong at this institution.
    How we measure the reach of our educational mission matters as much
    as how we measure ticket sales.

- **Capabilities without a mission use case are deprioritized.** When
    resources are constrained (and they always are), we choose depth
    over breadth. A well-governed, trustworthy platform serving six
    metric domains outperforms a sprawling one serving twenty poorly.

### 2. Trust is earned through accuracy, not speed.

*The people who rely on this institution extend a particular kind of
trust. That trust is incompatible with data that cannot be verified or
AI outputs that have not been reviewed.*

- **No metric is reported to leadership before it is defined and
    approved.** The metric definition gate is not a bureaucratic step;
    it is the mechanism by which we prevent the most common cause of
    stakeholder distrust: two departments calculating the same thing
    differently.

- **The data platform is the single source of truth.** Figures in a
    board presentation and figures in a staff dashboard agree because
    they draw from the same governed layer. Parallel spreadsheets,
    shadow databases, and local calculations are not alternatives; they
    are risks to be retired.

- **Pipelines are monitored continuously; failures are disclosed
    promptly.** Silence about a data quality issue is not neutrality. If
    a number is wrong and we know it, the right action is to flag it,
    not to let it circulate until someone outside the team notices.

- **AI output is not authoritative until a person has reviewed it.**
    Speed is not a sufficient reason to treat unreviewed AI output as
    fact. The cost of correcting a wrong number in a donor communication
    or a board packet is far higher than the cost of the review that
    prevented it.

### 3. Every number means exactly one thing.

*Definitional clarity is the foundation on which all reporting
credibility rests.*

- **Definitions are written before dashboards are built.** The
    sequence matters. A metric's calculation, grain, source, and known
    limitations are documented and approved before any model or report
    is built around it. Building first and defining later produces
    ambiguity that is very difficult to undo.

- **All business logic lives in the data platform.** Calculations,
    filters, and transformations that affect reported figures belong in
    the data platform not in Excel, and not in email threads. A figure
    whose derivation cannot be inspected in code cannot be trusted or
    governed.

- **Lineage is traceable from source to report.** Any metric in any
    report can be traced back to its source system and the
    transformations applied along the way. This is not optional; it is
    what makes audit, correction, and stakeholder explanation possible.

- **Metric disputes have a resolution process.** When two stakeholders
    disagree about a number, there is a defined path to resolution: the
    metric registry, the domain owner, and if necessary the AI & Data
    Committee. Disputes resolved by whoever shouts loudest are not
    resolved; they recur.

### 4. Humans remain accountable for every consequential decision.

*Artificial intelligence extends our capacity. It does not transfer our
responsibility.*

- **AI-generated code requires human review before deployment.** A
    pull request authored by an AI tool and approved by an engineer is
    the engineer's responsibility. The review is the point at which
    accountability is established, not a formality.

- **AI-derived metrics pass through the same definition gate as any
    other.** The method of derivation does not change the standard of
    rigor. A metric produced by a model requires the same documentation,
    domain owner approval, and registry registration as one produced by
    a human analyst.

- **Decision accountability is named, not diffused.** For every
    significant decision that AI informs, including donor segmentation,
    campaign targeting, attendance forecasting, there is a named person
    who is accountable for the decision and who understands the basis
    for it. "The model recommended it" is not an accountable answer.

- **Autonomous AI agents with write access to production systems
    require explicit authorization.** An AI that can modify the platform
    without human approval in the loop is a qualitatively different
    capability than one that generates suggestions. That distinction is
    governed, not assumed.

### 5. Risk determines rigor.

*Not all data and AI uses carry equal stakes. Controls should be
proportionate to the harm that could result if something goes wrong.*

- **AI tools are classified by the risk they pose, not by how they are
    marketed.** A tool described as a "productivity aid" that is used
    to draft donor communications or inform financial decisions is
    operating at a higher risk tier than its branding suggests.
    Classification is based on actual use, not vendor category.

- **The four-tier AI risk framework governs what controls are
    required.** From low-risk writing assistance (Tier 1) to high-stakes
    autonomous systems (Tier 4), the tier determines the approval
    requirement, data access limits, human review obligations, and
    disclosure requirements. The framework is detailed in the
    operational policy.

- **Change management controls are proportionate to change risk.** A
    documentation update and a credential rotation are not the same
    category of change. Governance controls such as approvals, freeze
    windows, and notification requirements, which scale to the potential
    blast radius of the change being made.

- **We are honest with ourselves about what harm could look like.**
    Risk classification is only useful if it is accurate. The tendency
    to underclassify, calling something low-risk because that requires
    less process, is a governance failure in its own right.

### 6. Privacy is the default, not an afterthought.

*Personal information about visitors, donors, members, and staff is
handled with the minimum collection, shortest retention, and most
restricted access that legitimate operations require.*

- **Data classification determines what AI tools may access.**
    Restricted data (personal, financial, and personnel records) does
    not flow into external AI services without a signed data processing
    agreement and explicit authorization. The classification is enforced
    in platform access controls, not left to individual judgment.

- **We collect what we need and retain it for as long as we must.**
    The default posture on data collection and retention is
    conservative. Longer retention and broader collection require a
    documented justification, not the other way around.

- **Vendors must meet our standards, not just their own.** Any third
    party receiving NS11MM data or operating AI on our behalf must
    execute a data processing agreement reviewed by legal counsel.
    Contractual clarity about data use, retention, and AI training is a
    precondition of the relationship, not an afterthought.

- **When in doubt, we choose the more protective path.** Privacy
    questions are rarely black and white. The tiebreaker is always the
    interest of the individual whose data we hold, not operational
    convenience, and not technical capability.

### 7. Accountability is how we improve, not how we punish.

*An institution that cannot name its failures cannot fix them. We hold
ourselves to the same standard of honesty that we ask of the history we
steward.*

- **Incidents are disclosed, documented, and reviewed.** Data quality
    failures, pipeline outages, AI errors, and security events are
    logged in a shared register, reviewed for root cause, and used to
    improve the system. The log is not a liability; it is evidence that
    the governance is working.

- **Post-incident reviews are completed, not waived.** For significant
    incidents, a written post-incident review is completed within five
    business days of resolution and shared with the AI & Data Committee.
    The review answers what happened, why it happened, and what changes
    will prevent recurrence.

- **Exceptions to policy are documented, not ignored.** When the right
    thing to do in a specific situation conflicts with a policy, the
    correct response is to request a formal exception, not to proceed
    quietly and hope no one notices. The exception register makes policy
    gaps visible so they can be addressed.

- **Questions are always welcome.** The intent of governance is not to
    restrict; it is to create shared clarity. Anyone in the organization
    should feel able to ask whether a planned use of data or AI is
    appropriate before proceeding. The VP of AI & Analytics is the first
    point of contact. Asking is never the wrong answer.

## IV. Governance Structure [to be developed]

This section will define the AI & Data Committee, including its
membership, meeting cadence, decision authority, and escalation paths.
It will also define the roles and responsibilities of the Data &
Analytics team and the metric domain owners across the organization's
six data domains.

> *Committee input requested: Are the right stakeholders represented in the AI & Data Committee? What decisions should require full council approval versus VP-level approval alone? How should the council interface with leadership?*

## V. Data Governance Framework [to be developed]

This section will operationalize Principles 2, 3, and 6. It will define
the platform architecture and its governance constraints (medallion
layers, dbt standards, Power BI conventions), the data classification
scheme (Restricted / Confidential / Internal / Public), the metric
definition gate process, data quality SLA tiers, and the change
management framework.

> *Committee input requested: Are the four classification levels (Critical, High, Medium, Low) right for NS11MM? What constitutes a "significant" data quality incident requiring escalation? Which change types should trigger freeze window restrictions?*

## VI. AI Governance Framework [to be developed]

This section will operationalize Principles 4 and 5. It will define the
four-tier AI risk framework in detail, specify the approved tools list
and its maintenance process, enumerate prohibited uses, and establish
the requirements for AI use in the data platform, including code review,
model documentation, and autonomous agent authorization.

> *Committee input requested: Should AI-generated content touching the memorial's core subject matter, specifically the events of September 11 and the people affected, be governed separately from other content uses? What does appropriate human oversight look like in that context?*

## VII. Compliance & Review [to be developed]

This section will define the quarterly AI & Data Committee review
agenda, the annual charter review process, the exception request and
approval workflow, and the approach to charter violations. It will also
define the training requirements for staff at different levels of data
and AI engagement.

> *Committee input requested: What cadence and format works for the AI & Data Committee given existing leadership meeting rhythms? What training should be required for all staff versus role-specific? How should this charter interface with existing HR and compliance frameworks?*

## Next Steps

This draft is submitted to the AI & Data Committee for discussion. The
committee is asked to:

1. Review the seven principles and their associated characteristics.
    Flag any that feel incomplete, inaccurate, or in tension with how
    the organization actually wants to operate.

2. Respond to the open questions embedded in Sections IV through VII.
    These questions are intended to surface the decisions that require
    committee input before the operational sections can be drafted.

3. Identify any material topics not covered by the current structure
    that should be addressed in the full charter.

Following committee review, the VP of AI & Analytics will incorporate
feedback and produce a complete first draft of the full charter for
ratification.