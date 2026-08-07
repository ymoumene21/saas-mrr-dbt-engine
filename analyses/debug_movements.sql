-- diagnostic: movement type breakdown with previous_mrr context
select
    mrr_movement_type,
    count(*) as cnt
from {{ ref('fct_mrr_movements') }}
group by mrr_movement_type
order by cnt desc
