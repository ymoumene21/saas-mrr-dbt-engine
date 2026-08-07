-- diagnostic: list stripe raw tables
select table_name
from {{ source('stripe', 'raw_subscriptions') }}.database.information_schema.tables
where table_schema = 'STRIPE'
