# Raw / Staging Models

Staging views that clean and rename columns from source tables in `NS11MM_DW_DEV_JMYERS.RAW`.

## Sources

| Source | Database | Schema | Status | Freshness |
|--------|----------|--------|--------|-----------|
| `gateway_seed` | NS11MM_DW_DEV_JMYERS | RAW | Active | warn 7d / error 14d |
| `counterpoint_seed` | NS11MM_DW_DEV_JMYERS | RAW | Active | warn 7d / error 14d |

## Key Design Notes

- All staging models deduplicate using `QUALIFY ROW_NUMBER() OVER (PARTITION BY <pk> ORDER BY _loaded_at DESC) = 1`
- Date columns use `try_to_timestamp()` for safe parsing
- `stg_gateway__tickets.ticket_date` is sourced from `endoflifedate` (not `ticketdate` which is empty in Galaxy)

## Enabled Models

### Gateway Ticketing Galaxy (`stg_gateway__*`)

| Model | Source Table | Primary Key |
|-------|-------------|-------------|
| `stg_gateway__acps` | SEED_GATE_ACPS | acp_id |
| `stg_gateway__coa` | SEED_GATE_COA | — |
| `stg_gateway__disbursementdetails` | SEED_GATE_DISBURSEMENTDETAILS | — |
| `stg_gateway__facility` | SEED_GATE_FACILITY | facility_id |
| `stg_gateway__items` | SEED_GATE_ITEMS | plu |
| `stg_gateway__jnldetails` | SEED_GATE_JNLDETAILS | — |
| `stg_gateway__jnlheaders` | SEED_GATE_JNLHEADERS | journal_header_id |
| `stg_gateway__jnlitems` | SEED_GATE_JNLITEMS | — |
| `stg_gateway__jnltickets` | SEED_GATE_JNLTICKETS | — |
| `stg_gateway__orderlines` | SEED_GATE_ORDERLINES | order_line_id |
| `stg_gateway__orders` | SEED_GATE_ORDERS | order_id |
| `stg_gateway__rmevents` | SEED_GATE_RMEVENTS | event_id |
| `stg_gateway__tickets` | SEED_GATE_TICKETS | ticket_id |
| `stg_gateway__usage` | SEED_GATE_USAGE | usage_id |
| `stg_gateway__vattribute` | SEED_GATE_VATTRIBUTE | — |
| `stg_gateway__vusage` | SEED_GATE_VUSAGE | — |

### NCR CounterPoint POS (`stg_counterpoint__*`)

| Model | Source Table | Primary Key |
|-------|-------------|-------------|
| `stg_counterpoint__imitem` | SEED_CP_IMITEM | item_no |
| `stg_counterpoint__pstkthist` | SEED_CP_PSTKTHIST | doc_id |
| `stg_counterpoint__pstkthistlin` | SEED_CP_PSTKTHISTLIN | doc_id + line_seq_no |
| `stg_counterpoint__vitkthist` | SEED_CP_VITKTHIST | doc_id |
| `stg_counterpoint__vitkthistlin` | SEED_CP_VITKTHISTLIN | doc_id + line_seq_no + seq_no |
