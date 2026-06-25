/*
  stg_wufoo__form_entries
  Source: wufoo.raw_wufoo_form_entries (NS11MM_DW_DEV.RAW)

  Wufoo API /forms/{formHash}/entries.json endpoint.
  IMPORTANT: Each form has different custom fields (Field1, Field2, etc.).
  The column names below are the standard Wufoo system fields present on
  every form. Custom form fields will appear as Field1...FieldN in _raw_data
  and must be mapped per-form once content is confirmed with Anna Kim.

  Table name in RAW may include form hash — confirm exact name after pipeline runs.
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('wufoo', 'raw_wufoo_form_entries') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:EntryId::varchar                         as entry_id,
        _raw_data:DateCreated::timestamp_tz                as submitted_at,
        _raw_data:DateUpdated::timestamp_tz                as updated_at,
        _raw_data:CreatedBy::varchar                       as created_by,
        _raw_data:UpdatedBy::varchar                       as updated_by,
        _raw_data:IP::varchar                              as submitter_ip,
        -- Standard name/contact fields present on most NS11MM forms
        -- TODO: confirm Field numbers for each form with Anna Kim
        _raw_data:Field1::varchar                          as field_1,
        _raw_data:Field2::varchar                          as field_2,
        _raw_data:Field3::varchar                          as field_3,
        _raw_data:Field4::varchar                          as field_4,
        _raw_data:Field5::varchar                          as field_5,
        _raw_data:Field6::varchar                          as field_6,
        _raw_data:Field7::varchar                          as field_7,
        _raw_data:Field8::varchar                          as field_8,
        _raw_data:Field9::varchar                          as field_9,
        _raw_data:Field10::varchar                         as field_10,
        _raw_data                                          as raw_entry,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
