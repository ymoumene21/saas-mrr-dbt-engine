-- dim_date: ONE ROW PER CALENDAR DAY — the "wall calendar" every dashboard filters by.
-- Built from our own data range, so it grows automatically as new events arrive.

with bounds as (

    -- First and last day we need: 1 Jan of the first event's year -> 31 Dec of the last event's year
    select
        date_trunc('year', min(event_at))::date                                   as start_date,
        (date_trunc('year', max(event_at)) + interval 1 year - interval 1 day)::date as end_date
    from {{ ref('stg_subscription_events') }}

),

days as (

    -- generate_series() makes a list of every date between start and end, 1 day apart.
    -- unnest() turns that list into one ROW per date.
    select unnest(generate_series(start_date, end_date, interval 1 day))::date as date_day
    from bounds

)

select
    date_day,                                                   -- primary key: 2025-03-14
    year(date_day)                          as year,            -- 2025
    quarter(date_day)                       as quarter,         -- 1
    month(date_day)                         as month,           -- 3
    strftime(date_day, '%B')                as month_name,      -- March
    strftime(date_day, '%Y-%m')             as year_month,      -- 2025-03 (sorts correctly as text)
    date_trunc('month', date_day)::date     as month_start,     -- 2025-03-01
    last_day(date_day)                      as month_end,       -- 2025-03-31
    date_day = last_day(date_day)           as is_month_end     -- true only on the last day of each month
from days