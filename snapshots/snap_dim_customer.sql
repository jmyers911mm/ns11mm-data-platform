/*
  snap_dim_customer
  SCD Type 2 snapshot tracking changes to customer dimension.
  STATUS: Awaiting dim_customer RAW data connection.
*/

{% snapshot snap_dim_customer %}

{{
    config(
        target_schema='INTERMEDIATE',
        unique_key='customer_id',
        strategy='check',
        check_cols=['customer_segment', 'membership_type', 'membership_status',
                    'primary_email', 'primary_phone', 'email_count', 'phone_count'],
        tags=['daily', 'non-critical']
    )
}}

select
    customer_id,
    crm_contact_id,
    full_name,
    primary_email,
    primary_phone,
    email_count,
    phone_count,
    membership_type,
    membership_status,
    customer_segment
from {{ ref('dim_customer') }}

{% endsnapshot %}
