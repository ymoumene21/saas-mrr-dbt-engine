-- diagnostic: current snapshot row status distribution
select
    status,
    count(*) as cnt
from {{ ref('sub_history_snapshot') }}
where dbt_valid_to is null
group by status
