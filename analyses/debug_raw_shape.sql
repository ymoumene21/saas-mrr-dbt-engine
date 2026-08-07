-- diagnostic: raw table shape
select
    count(*) as total_rows,
    count(distinct subscription_id) as distinct_subs
from {{ source('stripe', 'raw_subscriptions') }}
