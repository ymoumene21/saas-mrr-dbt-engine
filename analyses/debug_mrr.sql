-- diagnostic: snapshot version distribution
select
    count(*) as total_rows,
    count(distinct subscription_id) as distinct_subs,
    sum(case when version_count = 1 then 1 else 0 end) as subs_with_1_version,
    sum(case when version_count > 1 then 1 else 0 end) as subs_with_multiple_versions
from (
    select subscription_id, count(*) as version_count
    from {{ ref('sub_history_snapshot') }}
    group by subscription_id
) v
