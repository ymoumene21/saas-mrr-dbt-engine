WITH source AS (

    SELECT * FROM {{ source('stripe', 'raw_subscriptions') }}

),

renamed AS (

    SELECT

        -- IDs stay as-is, just explicitly named
        subscription_id,
        COALESCE(user_id, 'unknown') AS user_id,   -- fallback for missing user_id

        plan_name,
        status,

        -- explicit type casting: raw CSV loaded these as text
        mrr_amount::NUMBER(10,2)      AS mrr_amount,
        created_at::TIMESTAMP         AS created_at

    FROM source

)

SELECT * FROM renamed