-- stg_subscription_events: one row per thing that HAPPENED to a subscription
-- (created / upgraded / downgraded / cancelled), with the real business time.

with source as (

    select * from {{ source('stripe', 'raw_subscription_events') }}

),

renamed as (

    select
        subscription_id,
        coalesce(user_id, 'unknown')   as user_id,      -- same fallback as stg_subscriptions
        plan_name,
        lower(trim(status))            as status,       -- 'active' / 'cancelled'
        lower(trim(event_type))        as event_type,   -- 'created' / 'upgraded' / 'downgraded' / 'cancelled'
        mrr_amount::decimal(10,2)      as mrr_amount,   -- MRR AFTER this event happened
        created_at::timestamp          as created_at,   -- when the subscription first started
        event_at::timestamp            as event_at      -- when THIS event happened (business time)
    from source

)

select * from renamed