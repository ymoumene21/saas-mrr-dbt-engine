{{ config(materialized='external', location='exports/fct_mrr_movements.parquet') }}

select
    *,
    -- Date-only version of the event timestamp so Power BI can join it to
    -- dim_date.date_day (2025-03-04 10:23:00 -> 2025-03-04)
    cast(movement_date as date) as movement_day
from {{ ref('fct_mrr_movements') }}