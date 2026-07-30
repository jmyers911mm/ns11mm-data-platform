# Disabled Azure Pipelines

All 14 function-app CD pipelines live here because none of them can currently
deploy anything that runs: ingestion is seed-based today (RAW tables are loaded
from seeds/stage files, not from Azure Functions), and the function scaffolding
is incomplete — the `pipelines/<source>/` packages have no `function_app.py` or
`host.json`, the pipelines do not package `pipelines/shared/`, and the
`pipeline.py` source queries are unconfirmed placeholders. Re-enabling one
requires: adding `function_app.py` + `host.json` to the source's package,
packaging `pipelines/shared/` into the deploy artifact, confirming the source
system queries against the real system, and moving the YAML back to the repo
root.
