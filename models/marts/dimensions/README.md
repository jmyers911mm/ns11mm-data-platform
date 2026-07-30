# Mart Models — Dimensions

Conformed dimension tables for the NS11MM data warehouse.

## Enabled Models (13)

| Model | Description |
|-------|-------------|
| `dim_access_code` | Admission-type classification for Gateway access codes |
| `dim_coa` | Gateway chart of accounts for journal classification |
| `dim_customer` | Customer dimension from Gateway ticketing (one row per Gateway CUSTOMERID) |
| `dim_date` | Conformed date spine, 2000-01-01 to 2035-12-31 (calendar-based; no fiscal columns yet — fiscal calendar pending ADR-005 committee sign-off) |
| `dim_dpr_line_item` | DPR report line-item metadata and display config |
| `dim_event` | Timed-entry events, tours, programs, and shows |
| `dim_facility` | Conformed facility / selling-area dimension (911dw selling-area surrogate key) |
| `dim_gate` | Gate / access-control-point dimension for scan attribution |
| `dim_product` | Retail product (SKU) dimension from CounterPoint |
| `dim_retail_line_item` | Retail Performance Report line-item metadata + display config |
| `dim_store` | CounterPoint store dimension mapped to facility |
| `dim_ticket_type` | Ticket / pass / tour / merch item classification (Gateway PLU/item catalog) |
| `dim_tour_product` | Tour PLU → DPR line-item classification |

## Disabled Models (`enabled=false`) — in `disabled/` subfolder (4)

| Model | Blocked By | Re-enable When |
|-------|-----------|----------------|
| `dim_budget_version` | Vena plan versions (RAW.RAW_VENA_* empty) | Vena pipeline active and `MODELS` dict populated |
| `dim_campaign` | Salesforce NPS campaigns + fct_campaign_performance (SFMC) | SF/SFMC pipelines connected |
| `dim_fund` | Blackbaud Financial Edge accounts (RAW.RAW_BLACKBAUD_NXT_ACCOUNTS empty) | Blackbaud pipeline active |
| `dim_payment_method` | int_pos_retail (doesn't exist) + payment detail not in current extracts | POS payment-method feed landed and mart rewired |
