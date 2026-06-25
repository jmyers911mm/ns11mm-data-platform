{% macro check_source_freshness() %}
/*
  Per-source freshness thresholds for NS11MM platform.
  Called in on-run-start hooks to alert on stale Bronze data before dbt runs.

  Thresholds reflect nightly pipeline schedule (all sources load by 06:00 AM EST).
  Gateway and CounterPoint have slightly looser thresholds due to on-prem agent variability.

  UPDATE REQUIRED: Confirm exact table names once RAW schema is populated.
*/

{% set sources = [
    ('SALESFORCE_NPS',  'RAW_SALESFORCE_NPS_CONTACT',     60),
    ('SALESFORCE_MC',   'RAW_SALESFORCE_MC_TRACKING_SENT', 120),
    ('GATEWAY',         'RAW_GATEWAY_TRANSACTIONS',         180),
    ('COUNTERPOINT',    'RAW_COUNTERPOINT_TRANSACTIONS',    180),
    ('SHOPIFY',         'RAW_SHOPIFY_ORDERS',               60),
    ('CLASSY',          'RAW_CLASSY_TRANSACTIONS',          120),
    ('GA4',             'RAW_GA4_SESSIONREPORT',            120),
    ('GOOGLE_ADS',      'RAW_GOOGLE_ADS_CAMPAIGNPERFORMANCE', 120),
    ('META_ADS',        'RAW_META_ADS_CAMPAIGNINSIGHTS',    120),
    ('BLACKBAUD_NXT',   'RAW_BLACKBAUD_NXT_JOURNALENTRIES', 480),
    ('VENA',            'RAW_VENA_OPERATINGBUDGETFY26',     480),
    ('WUFOO',           'RAW_WUFOO_FORM_ENTRIES',           480),
    ('CLICKY',          'RAW_CLICKY_VISITORS',              120),
] %}

{% for source_system, table_name, warn_minutes in sources %}
    -- Check {{ source_system }}
    {% set freshness_query %}
        select
            '{{ source_system }}' as source_system,
            max(_extracted_at) as last_loaded,
            datediff('minute', max(_extracted_at), current_timestamp()) as minutes_since_load,
            case
                when datediff('minute', max(_extracted_at), current_timestamp()) > {{ warn_minutes }}
                then 'STALE'
                else 'FRESH'
            end as status
        from {{ target.database }}.RAW.{{ table_name }}
    {% endset %}
{% endfor %}

{% endmacro %}
