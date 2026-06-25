/*
  stg_drupal__pages
  Source: drupal.raw_drupal_page (NS11MM_DW_DEV.RAW)

  Drupal JSON:API /jsonapi/node/{content_type} endpoint.
  Field names follow Drupal JSON:API spec — data is nested under
  attributes and relationships keys.

  TODO: ADR-007 (DB vs API path) must be resolved before this model is built.
  TODO: Confirm content types in scope with Anna Kim.
  TODO: Confirm field names match your Drupal content type configuration.
*/

{{ config(materialized='view') }}

with source as (
    select _extracted_at, _record_id, _raw_data
    from {{ source('drupal', 'raw_drupal_page') }}
),

renamed as (
    select
        _extracted_at,
        _raw_data:id::varchar                              as node_id,
        _raw_data:type::varchar                            as content_type,
        _raw_data:attributes:title::varchar                as title,
        _raw_data:attributes:status::boolean               as is_published,
        _raw_data:attributes:created::timestamp_tz         as created_at,
        _raw_data:attributes:changed::timestamp_tz         as updated_at,
        _raw_data:attributes:promote::boolean              as is_promoted,
        _raw_data:attributes:sticky::boolean               as is_sticky,
        _raw_data:attributes:path:alias::varchar           as url_alias,
        _raw_data:attributes:langcode::varchar             as language_code,
        _raw_data:attributes:body:value::varchar           as body_html,
        _raw_data:attributes:body:summary::varchar         as body_summary,
        _raw_data:relationships:uid:data:id::varchar       as author_id,
        _raw_data                                          as raw_node,
        {{ generate_hashdiff(['_record_id', '_extracted_at::varchar']) }} as hashdiff
    from source
)

select * from renamed
