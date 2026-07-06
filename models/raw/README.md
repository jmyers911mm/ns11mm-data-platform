# Raw / Staging Models

Staging views that clean and rename columns from source tables in `NS11MM_DW_DEV_JMYERS.RAW`.

## Sources

| Source | Database | Schema | Status |
|--------|----------|--------|--------|
| `gateway_seed` | NS11MM_DW_DEV_JMYERS | RAW | Active |
| `counterpoint_seed` | NS11MM_DW_DEV_JMYERS | RAW | Active |

## Enabled Models

### Gateway Ticketing Galaxy (`stg_gateway__*`)

| Model | Source Table | Description |
|-------|-------------|-------------|
| `stg_gateway__acps` | SEED_GATE_ACPS | Access control points |
| `stg_gateway__coa` | SEED_GATE_COA | Chart of accounts |
| `stg_gateway__disbursementdetails` | SEED_GATE_DISBURSEMENTDETAILS | Payment disbursement details |
| `stg_gateway__facility` | SEED_GATE_FACILITY | Facilities / venues |
| `stg_gateway__items` | SEED_GATE_ITEMS | Product / ticket type catalog |
| `stg_gateway__jnldetails` | SEED_GATE_JNLDETAILS | Journal entry details |
| `stg_gateway__jnlheaders` | SEED_GATE_JNLHEADERS | Journal entry headers |
| `stg_gateway__jnlitems` | SEED_GATE_JNLITEMS | Journal items |
| `stg_gateway__jnltickets` | SEED_GATE_JNLTICKETS | Journal ticket associations |
| `stg_gateway__orderlines` | SEED_GATE_ORDERLINES | Order line items |
| `stg_gateway__orders` | SEED_GATE_ORDERS | Sales orders |
| `stg_gateway__rmevents` | SEED_GATE_RMEVENTS | Resource management events |
| `stg_gateway__tickets` | SEED_GATE_TICKETS | Issued tickets |
| `stg_gateway__usage` | SEED_GATE_USAGE | Ticket usage / scan events |
| `stg_gateway__vattribute` | SEED_GATE_VATTRIBUTE | Attribute values report view |
| `stg_gateway__vusage` | SEED_GATE_VUSAGE | Usage report view |

### NCR CounterPoint POS (`stg_counterpoint__*`)

| Model | Source Table | Description |
|-------|-------------|-------------|
| `stg_counterpoint__imitem` | SEED_CP_IMITEM | Item master / product catalog |
| `stg_counterpoint__pstkthist` | SEED_CP_PSTKTHIST | POS ticket history headers |
| `stg_counterpoint__pstkthistlin` | SEED_CP_PSTKTHISTLIN | POS ticket history line items |
| `stg_counterpoint__vitkthist` | SEED_CP_VITKTHIST | Ticket history view (headers) |
| `stg_counterpoint__vitkthistlin` | SEED_CP_VITKTHISTLIN | Ticket history view (lines) |

## Disabled Models (source not yet available)

The following source systems have been removed from this layer. Staging models for these were deleted; their corresponding intermediate models are disabled with `enabled=false`:

- Salesforce NPS (Sales Cloud)
- Salesforce Marketing Cloud
- Shopify
- GoFundMe Pro / Classy
- Blackbaud Financial Edge NXT
- Vena Solutions
- Google Analytics 4
- Google Ads
- Meta Ads
- Wufoo
- Clicky
- Drupal CMS
