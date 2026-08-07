-- diagnostic: raw subscription row counts and status
select
    status,
    count(*) as cnt
from {{ source('stripe', 'raw_subscriptions') }}
group by status
order by cnt desc
