#!/usr/bin/env python3
"""
Generate native Snowflake semantic-view DDL from the Cortex semantic view specs.

The `cortex_project/*.sv.yaml` files are the SINGLE authored source of truth for
every semantic view: tables, relationships, facts, dimensions, metrics, synonyms
and comments (ADR-005). The `scripts/deploy_semantic_view_<name>.sql` files are
GENERATED ARTIFACTS rendered from those specs — never hand-edit them; edit the
.sv.yaml and rerun this script.

Usage:
    python3 scripts/generate_semantic_view_ddl.py                      # all cortex_project/*.sv.yaml
    python3 scripts/generate_semantic_view_ddl.py cortex_project/DPR.sv.yaml
    python3 scripts/generate_semantic_view_ddl.py --database NS11MM_DW_PROD
    python3 scripts/generate_semantic_view_ddl.py --check              # exit 1 if any .sql drifted

Notes:
  * `cortex_project/disabled/` is skipped (scaffolds whose base tables are not built).
  * `module_custom_instructions` and `verified_queries` are not representable in
    CREATE SEMANTIC VIEW DDL; they deploy via the Cortex project (.sv.yaml) path.
  * Requires: python3 + PyYAML only.
"""

import argparse
import sys
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[1]
CORTEX_DIR = REPO / "cortex_project"
OUT_DIR = REPO / "scripts"


def load_model(path: Path) -> dict:
    return yaml.safe_load(path.read_text())


def q(text) -> str:
    """Single-quote a SQL string literal, escaping embedded single quotes."""
    return "'" + str(text if text is not None else "").replace("'", "''") + "'"


def flat(text) -> str:
    """Collapse a folded/multi-line YAML scalar into one line."""
    if text is None:
        return ""
    return " ".join(str(text).split())


def synonyms_sql(item: dict) -> str:
    syns = item.get("synonyms") or []
    if not syns:
        return ""
    return " WITH SYNONYMS = (" + ", ".join(q(flat(s)) for s in syns) + ")"


def comment_sql(item: dict) -> str:
    desc = flat(item.get("description"))
    if not desc:
        return ""
    return f" COMMENT = {q(desc)}"


def fqn(base_table: dict, database: str) -> str:
    return f"{database}.{base_table['schema']}.{base_table['table']}"


def render_member(table_name: str, item: dict) -> str:
    """One fact / dimension / metric entry: TBL.NAME AS expr [synonyms] [comment]."""
    expr = flat(item["expr"])
    return f"    {table_name}.{item['name']} AS {expr}{synonyms_sql(item)}{comment_sql(item)}"


def build(model: dict, database: str, source_rel: str) -> str:
    tables = model["tables"]
    schema = tables[0]["base_table"]["schema"]
    view_name = model["name"]

    lines = []
    lines.append("-- GENERATED FILE -- do not edit by hand.")
    lines.append(f"-- Source of truth: {source_rel}")
    lines.append("-- Regenerate: python3 scripts/generate_semantic_view_ddl.py")
    lines.append("-- Run as the MARTS owner role. Equivalent to redeploying the .sv.yaml via the")
    lines.append("-- Cortex project; use whichever path you have. Custom instructions and verified")
    lines.append("-- queries in the YAML deploy via the Cortex project path, not this DDL.")
    lines.append(f"CREATE OR REPLACE SEMANTIC VIEW {database}.{schema}.{view_name}")

    # ---- TABLES ----
    tbl_entries = []
    for t in tables:
        entry = f"    {t['name']} AS {fqn(t['base_table'], database)}"
        pk = t.get("primary_key", {}).get("columns") or []
        if pk:
            entry += " PRIMARY KEY (" + ", ".join(pk) + ")"
        entry += synonyms_sql(t) + comment_sql(t)
        tbl_entries.append(entry)
    lines.append("  TABLES (")
    lines.append(",\n".join(tbl_entries))
    lines.append("  )")

    # ---- RELATIONSHIPS ----
    rels = model.get("relationships") or []
    if rels:
        rel_entries = []
        for r in rels:
            lcols = ", ".join(c["left_column"] for c in r["relationship_columns"])
            rcols = ", ".join(c["right_column"] for c in r["relationship_columns"])
            rel_entries.append(
                f"    {r['name']} AS {r['left_table']} ({lcols}) "
                f"REFERENCES {r['right_table']} ({rcols})"
            )
        lines.append("  RELATIONSHIPS (")
        lines.append(",\n".join(rel_entries))
        lines.append("  )")

    # ---- FACTS ----
    fact_entries = []
    for t in tables:
        for f in t.get("facts") or []:
            fact_entries.append(render_member(t["name"], f))
    if fact_entries:
        lines.append("  FACTS (")
        lines.append(",\n".join(fact_entries))
        lines.append("  )")

    # ---- DIMENSIONS (per table: dimensions, then time_dimensions) ----
    dim_entries = []
    for t in tables:
        for d in t.get("dimensions") or []:
            dim_entries.append(render_member(t["name"], d))
        for d in t.get("time_dimensions") or []:
            dim_entries.append(render_member(t["name"], d))
    if dim_entries:
        lines.append("  DIMENSIONS (")
        lines.append(",\n".join(dim_entries))
        lines.append("  )")

    # ---- METRICS ----
    met_entries = []
    for t in tables:
        for m in t.get("metrics") or []:
            met_entries.append(render_member(t["name"], m))
    if met_entries:
        lines.append("  METRICS (")
        lines.append(",\n".join(met_entries))
        lines.append("  )")

    # ---- View COMMENT ----
    view_comment = flat(model.get("description"))
    if view_comment:
        lines.append(f"  COMMENT = {q(view_comment)}")

    return "\n".join(lines).rstrip() + ";\n"


def default_targets() -> list:
    return sorted(p for p in CORTEX_DIR.glob("*.sv.yaml"))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("yaml_paths", nargs="*",
                    help="One or more .sv.yaml files (default: all in cortex_project/, "
                         "skipping disabled/).")
    ap.add_argument("--database", default=None,
                    help="Override the target database (default: from each YAML's base_table).")
    ap.add_argument("--check", action="store_true",
                    help="Exit non-zero if any committed .sql differs from freshly "
                         "generated output (nothing is written).")
    args = ap.parse_args()

    targets = [Path(p).resolve() for p in args.yaml_paths] if args.yaml_paths else default_targets()
    if not targets:
        print("No .sv.yaml files found.", file=sys.stderr)
        return 1

    stale = []
    for yaml_path in targets:
        model = load_model(yaml_path)
        database = args.database or model["tables"][0]["base_table"]["database"]
        try:
            source_rel = yaml_path.relative_to(REPO).as_posix()
        except ValueError:
            source_rel = yaml_path.name
        ddl = build(model, database, source_rel)
        sql_path = OUT_DIR / f"deploy_semantic_view_{model['name'].lower()}.sql"

        if args.check:
            current = sql_path.read_text() if sql_path.exists() else ""
            if current != ddl:
                stale.append(sql_path.relative_to(REPO).as_posix())
        else:
            sql_path.write_text(ddl)
            n_metrics = sum(len(t.get("metrics") or []) for t in model["tables"])
            n_dims = sum(len((t.get("dimensions") or []) + (t.get("time_dimensions") or []))
                         for t in model["tables"])
            print(f"Wrote {sql_path.relative_to(REPO)}: {len(model['tables'])} tables, "
                  f"{n_dims} dimensions, {n_metrics} metrics, database={database}.")

    if args.check:
        if stale:
            print("Semantic-view DDL is stale for: " + ", ".join(stale), file=sys.stderr)
            print("Run `python3 scripts/generate_semantic_view_ddl.py` and stage the "
                  "regenerated .sql files.", file=sys.stderr)
            return 1
        print("All generated semantic-view DDL files are up to date.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
