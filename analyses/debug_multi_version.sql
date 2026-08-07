-- diagnostic: snapshot rows for multi-version subscription
select
    subscription_id,
    mrr_amount,
    status,
    plan_name,
    dbt_valid_from,
    dbt_valid_to
from {{ ref('sub_history_snapshot') }}
where subscription_id in (
    select subscription_id
    from {{ ref('sub_history_snapshot') }}
    group by subscription_id
    having count(*) > 1
)
