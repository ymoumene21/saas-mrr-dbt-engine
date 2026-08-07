-- diagnostic: subscriptions that should have expanded (higher mrr in raw history?)
select
    subscription_id,
    status,
    mrr_amount,
    plan_name
from {{ ref('stg_subscriptions') }}
where status = 'cancelled'
order by subscription_id
limit 20
