-- fct_mrr_movements: ONE ROW PER MRR CHANGE EVENT, dated in BUSINESS time.
-- Day 12: rebuilt on the event log (stg_subscription_events) instead of the snapshot,
-- so every created / upgraded / downgraded / cancelled event gets its real date.

with events as (

    select * from {{ ref('stg_subscription_events') }}

),

mrr_with_previous as (

    select
        subscription_id,
        user_id,
        plan_name,
        status,
        event_type,
        event_at as movement_date,              -- when it REALLY happened

        -- A cancelled subscription pays nothing, so its MRR after the event is 0.
        -- (The raw row still carries the old price, which would be misleading.)
        case
            when event_type = 'cancelled' then 0
            else mrr_amount
        end as current_mrr,

        -- LAG() = "look one row back" for the SAME subscription, in time order.
        -- The first event of every subscription has no row before it -> NULL.
        lag(mrr_amount) over (
            partition by subscription_id
            order by event_at
        ) as previous_mrr

    from events

)

select

    -- Stable unique ID: same subscription + same event time -> same hash every run
    md5(subscription_id || '-' || movement_date::varchar) as movement_id,

    subscription_id,
    user_id,
    plan_name,
    event_type,
    status,
    movement_date,
    previous_mrr,
    current_mrr,

    -- How much MRR moved: +99 for a new Pro sub, +300 for an upgrade, -499 for a churn.
    -- coalesce(previous_mrr, 0): a brand-new subscription moves up FROM zero.
    current_mrr - coalesce(previous_mrr, 0) as mrr_change,

    -- Same macro as Day 8 — it still works because the rules haven't changed
    {{ calculate_mrr_type('current_mrr', 'previous_mrr', 'status') }} as mrr_movement_type

from mrr_with_previous