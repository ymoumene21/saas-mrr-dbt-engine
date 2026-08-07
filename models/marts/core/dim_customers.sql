-- Dimension table: ONE ROW PER CUSTOMER.
-- Combines user metadata with an aggregated summary of their subscription activity.

with subscriptions as (

    select * from {{ ref('stg_subscriptions') }}
    -- ref() tells dbt "this model depends on stg_subscriptions" —
    -- it builds a dependency graph and runs things in the right order automatically

),

users as (

    select * from {{ ref('stg_users') }}

),

customer_agg as (

    -- Collapse subscriptions down to one row per user_id (this is the aggregation step)
    select
        user_id,
        min(created_at) as first_subscription_date,
        sum(case when status = 'active' then mrr_amount else 0 end) as total_active_mrr,
        max(case when status = 'active' then plan_name end) as current_plan
    from subscriptions
    group by user_id

)

select
    u.user_id,
    u.country,
    u.signup_date,
    c.first_subscription_date,
    c.total_active_mrr,
    c.current_plan
from users u
left join customer_agg c
    on u.user_id = c.user_id
-- LEFT JOIN, not INNER: we want to keep users even if they have zero subscriptions