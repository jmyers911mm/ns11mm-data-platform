# Schema Collection Request — Gateway Ticketing & CounterPoint

**To:** Kenny (IT Infrastructure)  
**From:** Jeremy Myers  
**Purpose:** Column names needed to finalize dbt staging models for Gateway Ticketing and NCR CounterPoint

---

## Instructions

For each table below, run the following SQL against the respective SQL Server instance and paste the results back. This only needs to be run once.

```sql
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = '<table_name>'
ORDER BY ORDINAL_POSITION;
```

---

## Gateway Ticketing Galaxy

**SQL Server instance:** [Kenny to confirm host/instance]  
**Database:** [Kenny to confirm database name]

Tables needed:

- `Transactions` — main ticket sales table
- `Reservations` — pre-booked reservations
- `TicketTypes` — ticket type reference data
- `Customers` — customer records
- `Sessions` — timed entry sessions/slots

---

## NCR CounterPoint SQL

**SQL Server instance:** [Kenny to confirm host/instance]  
**Database:** [Kenny to confirm — likely `cpdata` or similar]

Tables needed:

- `TKT_HIST` — transaction headers
- `TKT_HIST_LIN` — transaction line items
- `AR_CUST` — customer records
- `IM_ITEM` — inventory/product items

---

Once column names are confirmed, the staging models in
`models/staging/stg_gateway__*.sql` and `models/staging/stg_counterpoint__*.sql`
can be finalized. Current models use placeholder column names with TODO comments.
