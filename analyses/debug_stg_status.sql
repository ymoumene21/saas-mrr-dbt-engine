-- diagnostic: current subscription state in staging
select
    status,
    count(*) as cnt
from {{ ref('stg_subscriptions') }}
group by status
order by cnt desc
