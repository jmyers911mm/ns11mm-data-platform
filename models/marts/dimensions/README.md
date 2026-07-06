# Mart Models — Dimensions

Conformed dimension tables for the NS11MM data warehouse.

## Enabled Models

| Model | Description |
|-------|-------------|
| `dim_budget_version` | Budget version reference (Vena) |
| `dim_date` | Date dimension (generated) |
| `dim_fund` | Fund / campaign fund reference |
| `dim_marketing_channel` | Marketing channel reference (from seed) |

## Disabled Models (`enabled=false`)

| Model | Blocked By | Re-enable When |
|-------|-----------|----------------|
| `dim_campaign` | Salesforce NPS, fct_campaign_performance | SF pipeline connected |
| `dim_customer` | int_sf_crm, int_pos_tickets, int_pos_retail | SF + mart rewiring |
| `dim_gate` | int_ticket_scans (deleted) | Mart layer rewired to new silver models |
| `dim_payment_method` | int_pos_tickets, int_pos_retail (deleted) | Mart layer rewired |
| `dim_product` | int_pos_retail (deleted) | Mart layer rewired |
| `dim_ticket_type` | int_pos_tickets (deleted) | Mart layer rewired |
