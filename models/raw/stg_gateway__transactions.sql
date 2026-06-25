/*
  stg_gateway__transactions
  Source: gateway.raw_gateway_transactions (NS11MM_DW_DEV.RAW)

  Gateway Ticketing Galaxy SQL Server transactions table.
  Column names match SQL Server column names from the Galaxy database.

  TODO: Kenny must confirm exact column names by running:
    SELECT COLUMN_NAME, DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Transactions'
    ORDER BY ORDINAL_POSITION;
  against the Galaxy SQL Server instance.

  The placeholder columns below are based on typical Gateway Galaxy schemas.
  Replace with actual column names after Kenny confirms.
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('gateway', 'raw_gateway_transactions') }}
),

renamed as (
    select
        _extracted_at,
        -- TODO: Replace these field names with confirmed Gateway column names
        _raw_data:TransactionId::varchar                   as transaction_id,
        _raw_data:TransactionDate::date                    as transaction_date,
        _raw_data:TransactionTime::varchar                 as transaction_time,
        _raw_data:TicketTypeId::varchar                    as ticket_type_id,
        _raw_data:Quantity::integer                        as quantity,
        _raw_data:UnitPrice::number(10,2)                  as unit_price,
        _raw_data:TotalAmount::number(10,2)                as total_amount,
        _raw_data:PaymentMethod::varchar                   as payment_method,
        _raw_data:SessionId::varchar                       as session_id,
        _raw_data:EntryDate::date                          as entry_date,
        _raw_data:EntryTime::varchar                       as entry_time,
        _raw_data:GateId::varchar                          as gate_id,
        _raw_data:CustomerId::varchar                      as customer_id,
        _raw_data:OrderId::varchar                         as order_id,
        _raw_data:SalesChannelId::varchar                  as sales_channel,
        _raw_data:DiscountCode::varchar                    as discount_code,
        _raw_data:DiscountAmount::number(10,2)             as discount_amount,
        _raw_data:IsMember::boolean                        as is_member,
        _raw_data:LastModified::timestamp                  as last_modified_at,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
