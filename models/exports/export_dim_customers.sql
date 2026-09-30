{{ config(materialized='external', location='exports/dim_customers.parquet') }}

select * from {{ ref('dim_customers') }}