/*
  snap_sf_crm — SCD Type 2 snapshot on Salesforce NPS contact dimension.
  STATUS: Awaiting stg_salesforce_nps__contacts RAW connection.
*/

{% snapshot snap_sf_crm %}

{{
    config(
        target_schema='SILVER',
        unique_key='contact_id',
        strategy='check',
        check_cols=['hashdiff'],
        tags=['daily', 'non-critical']
    )
}}

-- STATUS: Awaiting RAW connection
select * from {{ ref('stg_salesforce_nps__contacts') }}

{% endsnapshot %}
