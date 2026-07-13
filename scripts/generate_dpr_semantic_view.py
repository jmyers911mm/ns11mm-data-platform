#!/usr/bin/env python3
"""
Generate the native Snowflake semantic-view DDL from the DPR Cortex YAML.

`semantic_models/dpr.yaml` is the single authored source of truth for every DPR
metric, dimension, and relationship (ADR-005 / ADR-008). This script renders the
`CREATE OR REPLACE SEMANTIC VIEW` twin so it never has to be hand-maintained and
can never drift from the YAML. Do not edit the generated .sql by hand.

Usage:
    python scripts/generate_dpr_semantic_view.py                 # dev (database from YAML)
    python scripts/generate_dpr_semantic_view.py --database NS11MM_DW_PROD
    python scripts/generate_dpr_semantic_view.py --check         # fail if the .sql is stale

Requires: pyyaml.
"""

import argparse
import sys
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[1]
YAML_PATH = REPO / "semantic_models" / "dpr.yaml"
SQL_PATH = REPO / "semantic_models" / "create_dpr_semantic_view.sql"

# Short table aliases used inside the semantic view. Kept explicit (rather than
# reusing the YAML logical names) because `date` is a Snowflake keyword and the
# native DDL needs a safe alias. Add an entry here when a new table is added.
ALIAS_OVERRIDES = {"daily_performance": "dp", "date": "dt"}


def alias_for(table_name: str) -> str:
    if table_name in ALIAS_OVERRIDES:
        return ALIAS_OVERRIDES[table_name]
    # Fallback: initials of underscore-separated words, else first two chars.
    parts = table_name.split("_")
    if len(parts) > 1:
        return "".join(p[0] for p in parts if p)[:4].lower()
    return table_name[:2].lower()


def load_model(path: Path) -> dict:
    raw = path.read_text()
    # The file carries a `--` SQL-style header comment block that is not valid
    # YAML. Strip those lines before parsing. `#` comments are valid YAML.
    cleaned = "\n".join(l for l in raw.splitlines() if not l.lstrip().startswith("--"))
    return yaml.safe_load(cleaned)


def q(text: str) -> str:
    """Single-quote a SQL string literal, escaping embedded single quotes."""
    if text is None:
        text = ""
    return "'" + str(text).replace("'", "''") + "'"


def flat(text: str) -> str:
    """Collapse a folded/multi-line YAML scalar into one line."""
    if text is None:
        return ""
    return " ".join(str(text).split())


def synonyms_clause(item: dict) -> str:
    syns = item.get("synonyms") or []
    if not syns:
        return ""
    inner = ", ".join(q(s) for s in syns)
    return f"        WITH SYNONYMS = ({inner})\n"


def comment_clause(item: dict, terminal: bool) -> str:
    desc = flat(item.get("description"))
    end = "" if terminal else ","
    if not desc:
        # Still need the terminator on the identifier line; caller handles that.
        return ""
    return f"        COMMENT = {q(desc)}{end}"


def render_member(alias: str, item: dict, expr_key: str, terminal: bool) -> str:
    """Render one dimension or metric member with synonyms + comment."""
    name = item["name"]
    expr = flat(item[expr_key])
    head = f"    {alias}.{name} AS {expr}\n"
    syn = synonyms_clause(item)
    desc = flat(item.get("description"))
    end = "" if terminal else ","
    if desc:
        tail = f"        COMMENT = {q(desc)}{end}\n"
    else:
        # No comment: the terminator goes on whichever line is last.
        if syn:
            syn = syn.rstrip("\n") + end + "\n"
        else:
            head = head.rstrip("\n") + end + "\n"
        tail = ""
    return head + syn + tail


def build(model: dict, database: str) -> str:
    tables = model["tables"]
    schema = tables[0]["base_table"]["schema"]
    view_name = model["name"].upper()

    lines = []
    lines.append("-- GENERATED FILE. Do not edit by hand.")
    lines.append("-- Source: semantic_models/dpr.yaml")
    lines.append("-- Regenerate: python scripts/generate_dpr_semantic_view.py")
    lines.append("--")
    lines.append("-- Environment-portable via USE DATABASE. Change the target with")
    lines.append("--   python scripts/generate_dpr_semantic_view.py --database NS11MM_DW_PROD")
    lines.append(f"USE DATABASE {database};")
    lines.append(f"USE SCHEMA {schema};")
    lines.append("")
    lines.append(f"CREATE OR REPLACE SEMANTIC VIEW {schema}.{view_name}")

    # ---- TABLES ----
    lines.append("TABLES (")
    tbl_blocks = []
    for t in tables:
        alias = alias_for(t["name"])
        bt = t["base_table"]
        pk = ", ".join(c.lower() for c in t.get("primary_key", {}).get("columns", []))
        block = [f"    {alias} AS {bt['schema']}.{bt['table']}"]
        if pk:
            block.append(f"        PRIMARY KEY ({pk})")
        syns = t.get("synonyms") or []
        if syns:
            block.append("        WITH SYNONYMS = (" + ", ".join(q(s) for s in syns) + ")")
        desc = flat(t.get("description"))
        if desc:
            block.append(f"        COMMENT = {q(desc)}")
        tbl_blocks.append("\n".join(block))
    lines.append(",\n".join(tbl_blocks))
    lines.append(")")

    # ---- RELATIONSHIPS ----
    rels = model.get("relationships") or []
    if rels:
        lines.append("RELATIONSHIPS (")
        rel_blocks = []
        for r in rels:
            la = alias_for(r["left_table"])
            ra = alias_for(r["right_table"])
            lcols = ", ".join(c["left_column"].lower() for c in r["relationship_columns"])
            rcols = ", ".join(c["right_column"].lower() for c in r["relationship_columns"])
            rel_blocks.append(f"    {r['name']} AS {la} ({lcols}) REFERENCES {ra} ({rcols})")
        lines.append(",\n".join(rel_blocks))
        lines.append(")")

    # ---- DIMENSIONS (time_dimensions first, then dimensions, across all tables) ----
    dim_members = []
    for t in tables:
        alias = alias_for(t["name"])
        for d in t.get("time_dimensions", []) or []:
            dim_members.append((alias, d))
        for d in t.get("dimensions", []) or []:
            dim_members.append((alias, d))
    if dim_members:
        lines.append("DIMENSIONS (")
        rendered = []
        for i, (alias, d) in enumerate(dim_members):
            rendered.append(render_member(alias, d, "expr", terminal=(i == len(dim_members) - 1)))
        lines.append("".join(rendered).rstrip("\n"))
        lines.append(")")

    # ---- METRICS (across all tables) ----
    met_members = []
    for t in tables:
        alias = alias_for(t["name"])
        for m in t.get("metrics", []) or []:
            met_members.append((alias, m))
    if met_members:
        lines.append("METRICS (")
        rendered = []
        for i, (alias, m) in enumerate(met_members):
            rendered.append(render_member(alias, m, "expr", terminal=(i == len(met_members) - 1)))
        lines.append("".join(rendered).rstrip("\n"))
        lines.append(")")

    # ---- View COMMENT + AI instructions ----
    view_comment = flat(model.get("description"))
    if view_comment:
        lines.append(f"COMMENT = {q(view_comment)}")

    mci = model.get("module_custom_instructions") or {}
    sql_gen = flat(mci.get("sql_generation"))
    qcat = flat(mci.get("question_categorization"))
    if sql_gen:
        lines.append(f"AI_SQL_GENERATION {q(sql_gen)}")
    if qcat:
        lines.append(f"AI_QUESTION_CATEGORIZATION {q(qcat)}")

    return "\n".join(lines).rstrip() + ";\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--database", default=None,
                    help="Target database for USE DATABASE (default: from dpr.yaml base_table).")
    ap.add_argument("--check", action="store_true",
                    help="Exit non-zero if the committed .sql differs from freshly generated output.")
    args = ap.parse_args()

    model = load_model(YAML_PATH)
    database = args.database or model["tables"][0]["base_table"]["database"]
    ddl = build(model, database)

    if args.check:
        current = SQL_PATH.read_text() if SQL_PATH.exists() else ""
        if current != ddl:
            print("create_dpr_semantic_view.sql is stale. Run "
                  "`python scripts/generate_dpr_semantic_view.py` and commit.", file=sys.stderr)
            return 1
        print("create_dpr_semantic_view.sql is up to date.")
        return 0

    SQL_PATH.write_text(ddl)
    n_metrics = sum(len(t.get("metrics", []) or []) for t in model["tables"])
    n_dims = sum(len((t.get("dimensions") or []) + (t.get("time_dimensions") or []))
                 for t in model["tables"])
    print(f"Wrote {SQL_PATH.relative_to(REPO)}: {n_metrics} metrics, {n_dims} dimensions, "
          f"database={database}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())