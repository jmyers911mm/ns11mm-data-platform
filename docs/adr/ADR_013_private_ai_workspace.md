# ADR-013: Private AI Workspace: Self-Hosted Inference for Sensitive Data

**Status:** Proposed (drafted from the ADR Review working document; decision pending the Jeremy/Diana review session)
**Category:** AI / Analytics
**Date:** August 5, 2026
**Deciders:** Jeremy Myers (VP AI & Analytics)
**Consulted:** Michael Cartier (CIO — executive approval in principle already given); IT for GPU VM procurement
**Related:** AI Charter (four-tier AI risk framework), Data Classification policy, ADR-001 (Stack Selection)

> **Source note.** Drafted from the ADR Review working document (Part 2, ADR-013); decision box empty, recommended option drafted pending the session. The self-hosted stack (Ollama on an Azure GPU VM, Phi-4 14B) has executive approval in principle and is pending GPU VM procurement [confirm procurement status].

## Context

The private AI initiative — Ollama on an Azure GPU VM running Phi-4 14B — exists so that sensitive institutional data can be processed by AI without leaving the NS11MM Azure boundary. The architectural decision behind it, self-hosted inference for sensitive data versus third-party inference endpoints, has been made informally but never documented.

Without this ADR, the boundary between what can use the Anthropic API (NS11MM AI Digest, the Hub tools) and what must stay on-premises will be relitigated for every new use case as AI tooling proliferates. The AI Charter's four-tier risk framework and the Data Classification policy already exist; this decision must align with both rather than invent a parallel scheme.

## Decision

**AI inference is routed by data sensitivity, per the Data Classification policy:**

- **Restricted and Confidential data:** self-hosted inference only — the approved stack is Ollama with Phi-4 14B on the Azure GPU VM, inside the NS11MM Azure boundary. No third-party endpoint may receive this data.
- **Internal and Public data:** the Anthropic API and other approved third-party endpoints are permitted.
- **New AI tools require Jeremy's approval before use with any NS11MM data.** The approved tool list is maintained as an appendix to this ADR. [confirm initial tool list]
- Routing decisions align with the AI Charter's four-tier risk framework; a conflict between this ADR and the Charter is resolved in the Charter's favor and this ADR is amended.

## Options considered

### Option A: Sensitivity-based routing (recommended)

Wins because it gives staff a clear, self-service rule keyed to a classification scheme they already use, preserves the high-value third-party use cases (AI Digest, Hub tools) for non-sensitive data, and confines the cost and capability ceiling of self-hosting to the data that actually requires it.

### Option B: All inference self-hosted (set aside)

Its genuine advantage: the maximum security posture — no NS11MM data ever reaches a third party, and no classification judgment can fail. Set aside because it eliminates the existing Anthropic API use cases unless a separate exception process is built (recreating this same boundary question in inverted form), and it caps every AI use case at the capability of a 14B local model.

### Option C: Case-by-case assessment by Jeremy (set aside)

Its genuine advantage: full flexibility, and every decision gets expert judgment. Set aside because it creates inconsistency across cases, queues every AI experiment on one person, and gives staff no guidance on what they may do independently — the relitigation problem this ADR exists to end.

## Consequences

**Positive**
- The sensitive-data boundary is a written rule, not a per-case negotiation; staff can self-serve the answer.
- Third-party AI capability remains available where classification permits, so the platform is not paying the local-model capability ceiling everywhere.
- The approved-tool appendix gives governance a single place to look.

**Negative**
- The GPU VM is a new operational surface with real cost (procurement, patching, model updates) owned by a small team.
- Routing correctness depends on data being classified correctly upstream; a misclassified dataset routes to the wrong boundary silently.
- Phi-4 14B is materially less capable than frontier hosted models; sensitive-data use cases inherit that gap.

**Accepted risks**
- Classification of edge-case datasets (mixed sensitivity, derived data) will still need judgment; the Data Classification policy, not this ADR, is where those calls are made.

## Revisit trigger

Reopen when the GPU VM procurement lands and pilot results are in (capability adequacy of Phi-4 14B), if the Data Classification policy or AI Charter tiers change, or if a vendor offers an in-boundary deployment (for example, private endpoints contractually confined to the NS11MM Azure tenant) that changes the self-host-versus-third-party economics — whichever comes first.
