-- Serving-counter copy of fct_mrr_monthly for Power BI.
-- materialized='external' = write the result to a file instead of a DB table
-- location = where the file goes (relative to the project root)
{{ config(materialized='external', location='exports/fct_mrr_monthly.parquet') }}

select * from {{ ref('fct_mrr_monthly') }}