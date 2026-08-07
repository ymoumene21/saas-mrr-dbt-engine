-- diagnostic: how many subs have ever had status or mrr change in snapshot history
select
    count(distinct subscription_id) as subs_with_history
from (
    select subscription_id
    from {{ ref('sub_history_snapshot') }}
    group by subscription_id
    having count(*) > 1
) x
