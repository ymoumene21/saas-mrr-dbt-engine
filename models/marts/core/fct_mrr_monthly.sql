-- fct_mrr_monthly: ONE ROW PER SUBSCRIPTION PER MONTH-END.
-- The "balance" table: what was each subscription paying on the last day of each month?
-- (fct_mrr_movements = the transactions; this = the month-end balance.)

with movements as (

    select * from {{ ref('fct_mrr_movements') }}

),

month_ends as (

    -- Every month-end from the calendar, up to the month of our latest event
    -- (we don't want empty future months like Dec 2026)
    select date_day as month_end
    from {{ ref('dim_date') }}
    where is_month_end
      and date_day <= (select last_day(max(movement_date)::date) from movements)

),

subscription_months as (

    -- Pair each subscription with every month-end ON or AFTER the month it started
    select
        m.subscription_id,
        m.user_id,
        me.month_end
    from movements m
    join month_ends me
        on me.month_end >= last_day(m.movement_date::date)
    where m.event_type = 'created'      -- one starting point per subscription

),

latest_event as (

    -- For each subscription + month-end, find the LAST event that happened on or before
    -- that day. Its current_mrr is what the customer was paying at month-end.
    select
        sm.subscription_id,
        sm.user_id,
        sm.month_end,
        mv.plan_name,
        mv.current_mrr   as mrr,
        mv.event_type    as last_event_type
    from subscription_months sm
    join movements mv
        on  mv.subscription_id = sm.subscription_id
        and mv.movement_date::date <= sm.month_end
    -- qualify = "filter on a window function". row_number() = 1 keeps only the newest event.
    qualify row_number() over (
        partition by sm.subscription_id, sm.month_end
        order by mv.movement_date desc
    ) = 1

)

select
    md5(subscription_id || '-' || month_end::varchar) as subscription_month_id,  -- unique key
    subscription_id,
    user_id,
    month_end,
    plan_name,
    mrr,                                               -- 0 once the subscription has churned
    last_event_type <> 'cancelled' as is_active        -- true = still a paying customer this month
from latest_event