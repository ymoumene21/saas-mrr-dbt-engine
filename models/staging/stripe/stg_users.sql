with source as (
    select * from {{ source('stripe', 'raw_users') }}
),

renamed as (
    select
        user_id,
        upper(trim(country)) as country,      -- standardize casing/whitespace, same convention as stg_subscriptions
        cast(signup_date as timestamp) as signup_date
    from source
)

select * from renamed