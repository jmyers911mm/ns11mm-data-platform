# Cortex Project

Canonical home for all Snowflake Cortex Analyst semantic views and Cortex Agent
specs. Managed by the `semantic_studio` tooling in Cortex Code.

## Contents

| File | Type | Deploy Target | Status |
|---|---|---|---|
| `DPR.sv.yaml` | Semantic View | `NS11MM_DW_DEV.MARTS.DPR` | Deployed |
| `UNIFIED.sv.yaml` | Semantic View | `NS11MM_DW_DEV.MARTS.UNIFIED` | Ready |
| `ATTENDANCE.sv.yaml` | Semantic View | `NS11MM_DW_DEV.MARTS.ATTENDANCE` | Ready |
| `RETAIL.sv.yaml` | Semantic View | `NS11MM_DW_DEV.MARTS.RETAIL` | Ready |
| `disabled/FUNDRAISING_ECOM.sv.yaml` | Semantic View | — | Scaffold in `disabled/` — all four base dims are disabled dbt models; awaiting the fundraising dims. Not in the manifest; cannot deploy. |
| `DPR_ANALYST.agent.yaml` | Cortex Agent | `NS11MM_DW_DEV.MARTS.DPR_ANALYST` | Deployed |
| `cortex-project.yaml` | Manifest | — | Tracks all artifacts |

## Deploy

Semantic views and agents are deployed via `semantic_view_deploy` and
`cortex_agent_deploy` actions in Cortex Code. The `cortex-project.yaml`
manifest maps each file to its Snowflake FQN.

```
# Deploy a semantic view:
semantic_studio → semantic_view_deploy → file_path + fqn

# Deploy an agent:
semantic_studio → cortex_agent_deploy → fqn (resolves file from manifest)
```

After deploying a semantic view, grant access:
```sql
GRANT USAGE ON SEMANTIC VIEW MARTS.<VIEW_NAME> TO ROLE <role>;
```

## Architecture

```
cortex_project/
├── cortex-project.yaml          # manifest (auto-maintained)
├── *.sv.yaml                    # semantic view specs
├── *.agent.yaml                 # agent specs
└── disabled/                    # scaffolds whose base tables are not yet built
```

- **Semantic views** define tables, dimensions, metrics, relationships, verified
  queries, and custom instructions for Cortex Analyst.
- **Agent specs** define tools (Cortex Analyst, Cortex Search), orchestration,
  instructions, and tool resources.
- **Manifest** tracks which file maps to which Snowflake object for deploy.

## Conventions

- One `.sv.yaml` per deployed semantic view
- One `.agent.yaml` per deployed agent
- Governance metadata (MET-### IDs, owners, SLA tiers) lives in dbt exposure
  `meta:` blocks, not in the semantic view YAML
- The `.sv.yaml` files are the single authored source of truth. The
  `scripts/deploy_semantic_view_*.sql` DDL files are generated from them by
  `scripts/generate_semantic_view_ddl.py` — never hand-edit the SQL
  (a pre-commit hook runs `--check` to catch drift)
- Design documentation lives in `docs/architecture/BUILD_DIMS_METS.md`
