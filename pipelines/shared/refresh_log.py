# Shared utility to append table refresh details to a markdown log file.
"""
Append table-level refresh details to docs/REFRESH_LOG.md after each pipeline run.

Usage (inside a pipeline's run() function):
    from shared.refresh_log import RefreshLogger

    logger = RefreshLogger(SOURCE_SYSTEM)
    logger.add("Transactions", "success", 1234)
    logger.add("Customers", "failed", 0, "timeout")
    logger.write()
"""

import os
from datetime import datetime, timezone
from pathlib import Path


# Resolve the repo root (two levels up from pipelines/shared/)
_REPO_ROOT = Path(__file__).resolve().parent.parent.parent
_LOG_FILE = _REPO_ROOT / "docs" / "REFRESH_LOG.md"


class RefreshLogger:
    """Collects per-table results during a pipeline run, then appends to the log."""

    def __init__(self, source_system: str, mode: str = "incremental"):
        self.source_system = source_system
        self.mode = mode
        self.started_at = datetime.now(timezone.utc)
        self.entries: list[dict] = []

    def add(self, table_name: str, status: str, records: int, error: str | None = None):
        self.entries.append({
            "table": table_name,
            "status": status,
            "records": records,
            "error": error,
        })

    def write(self):
        """Append a markdown section summarising this pipeline run."""
        finished_at = datetime.now(timezone.utc)

        lines = [
            f"## {self.source_system} — {self.mode}",
            f"**Run started:** {self.started_at.strftime('%Y-%m-%d %H:%M:%S UTC')}  ",
            f"**Run finished:** {finished_at.strftime('%Y-%m-%d %H:%M:%S UTC')}",
            "",
            "| Table | Status | Records | Error |",
            "|-------|--------|--------:|-------|",
        ]

        for e in self.entries:
            error_text = e["error"] or "—"
            lines.append(
                f"| {e['table']} | {e['status']} | {e['records']:,} | {error_text} |"
            )

        total = sum(e["records"] for e in self.entries)
        failed = sum(1 for e in self.entries if e["status"] != "success")
        lines.append("")
        lines.append(f"**Total records landed:** {total:,}  ")
        if failed:
            lines.append(f"**Tables with errors:** {failed}")
        lines.append("")
        lines.append("---")
        lines.append("")

        section = "\n".join(lines)

        # Ensure the file and parent directory exist
        _LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
        if not _LOG_FILE.exists():
            header = "# Pipeline Refresh Log\n\nAuto-generated after each pipeline ingestion run.\n\n---\n\n"
            _LOG_FILE.write_text(header)

        with open(_LOG_FILE, "a") as f:
            f.write(section)

        print(f"    Refresh log appended to {_LOG_FILE.relative_to(_REPO_ROOT)}")
