-- Fact table: ONE ROW PER MRR CHANGE EVENT.
-- Built from the SCD Type 2 snapshot, so we have full history of every plan/price change.
-- fct_mrr_movements: one row per MRR change event, classified by movement type

with snapshot as (

    -- sub_history_snapshot (Day 6) already tracks every change to mrr_amount
    -- over time, with dbt_valid_from marking when each version became true
    select * from {{ ref('sub_history_snapshot') }}
    -- ref() works on snapshots too — dbt treats them the same as models

),

mrr_with_previous as (

    select
        subscription_id,
        user_id,
        plan_name,
        mrr_amount as current_mrr,
        status,
        dbt_valid_from as movement_date,

        -- LAG() grabs the mrr_amount from the row "one snapshot back"
        -- for this SAME subscription_id, ordered chronologically
        lag(mrr_amount) over (
            partition by subscription_id
            order by dbt_valid_from
        ) as previous_mrr

    from snapshot

)

select

 -- movement_id: a manufactured unique ID for this specific event.
    -- MD5() hashes the combination of subscription_id + movement_date into
    -- one fixed-length string. Same inputs always produce the same hash,
    -- so this ID is stable and reproducible every time dbt runs.
    md5(subscription_id || '-' || movement_date::string) as movement_id,

    subscription_id,
    user_id,
    plan_name,
    current_mrr,
    previous_mrr,
    status,
    movement_date,

    -- calling our macro here — dbt will compile this into a full CASE WHEN
    {{ calculate_mrr_type('current_mrr', 'previous_mrr', 'status') }} as mrr_movement_type

from mrr_with_previous
