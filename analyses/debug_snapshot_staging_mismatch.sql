-- diagnostic: compare snapshot current rows vs staging for status mismatches
select
    count(*) as mismatch_count
from {{ ref('sub_history_snapshot') }} s
join {{ ref('stg_subscriptions') }} stg
    on s.subscription_id = stg.subscription_id
where s.dbt_valid_to is null
  and s.status != stg.status
