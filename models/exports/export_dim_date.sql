{{ config(materialized='external', location='exports/dim_date.parquet') }}

select * from {{ ref('dim_date') }}