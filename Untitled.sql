select * from NS11MM_DW_DEV.{{ target.schema }}.{{ model_name }}
minus
select * from NS11MM_DW_PROD.MARTS.{{ model_name }}