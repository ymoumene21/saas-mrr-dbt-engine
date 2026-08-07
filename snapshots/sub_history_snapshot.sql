{% snapshot sub_history_snapshot %}
-- This snapshot block tells dbt to version-track this table over time
-- 'sub_history_snapshot' is the name of the resulting table in Snowflake

{{
    config(
        target_schema='snapshots',
        unique_key='subscription_id',
        strategy='check',
        check_cols=['mrr_amount', 'plan_name', 'status']
    )
}}
-- target_schema: which schema to build this table in
-- unique_key: the column that identifies one subscription across all its versions
-- strategy='check': compare column VALUES to detect a change
-- check_cols: if ANY of these change, snapshot a new row

select
    subscription_id,
    user_id,
    plan_name,
    mrr_amount,
    status,
    created_at
from {{ ref('stg_subscriptions') }}
-- ref() points dbt at your existing stg_subscriptions VIEW, not the raw table

{% endsnapshot %}
