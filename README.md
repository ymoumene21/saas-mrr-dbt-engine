# SaaS MRR Analytics Engine

A dbt project that turns raw Stripe subscription data into tested, reliable MRR (Monthly Recurring Revenue) metrics — the kind of pipeline a SaaS company's finance and growth teams would actually rely on to track revenue movements over time.

[![dbt CI Pipeline](https://github.com/ymoumene21/saas-mrr-dbt-engine/actions/workflows/dbt_ci.yml/badge.svg)](https://github.com/ymoumene21/saas-mrr-dbt-engine/actions/workflows/dbt_ci.yml)

## The problem this solves

Raw subscription data only tells you the *current* state of a subscription - active, cancelled, etc. It doesn't tell you *how revenue changed over time*: which customers are new, which upgraded, which downgraded, and which churned. Answering that requires tracking subscription status changes historically, not just querying the latest snapshot.

This project builds that history from scratch and classifies every change into one of four standard SaaS revenue movement types: **New, Expansion, Contraction, Churn**.

## Pipeline architecture

Stripe (raw data in Snowflake, SAAS_RAW.STRIPE)
|
v
staging layer clean + standardise raw source columns
(stg_users, stg_subscriptions)
|
v
snapshot layer tracks subscription status changes over time (SCD Type 2)
(sub_history_snapshot)
|
v
marts layer business-ready, tested tables
(dim_customers, fct_mrr_movements)


## Models

| Layer | Model | What it does |
|---|---|---|
| Staging | `stg_users` | Cleaned, standardised customer records from Stripe |
| Staging | `stg_subscriptions` | Cleaned, standardised subscription records from Stripe |
| Snapshot | `sub_history_snapshot` | Captures subscription status at each point in time, so changes can be detected historically instead of only seeing the current state |
| Marts | `dim_customers` | One row per customer, with lifetime MRR and current plan status |
| Marts | `fct_mrr_movements` | Event-level fact table - one row per detected MRR movement (New / Expansion / Contraction / Churn), built from the snapshot history |

## Data quality

Every mart model is tested on every single code push via CI, not just run once manually:

- **Uniqueness & not-null checks** on primary keys (`user_id`, `movement_id`)
- **Referential integrity** - every `fct_mrr_movements` row must map to a real customer in `dim_customers`
- **Accepted values** - `mrr_movement_type` can only ever be `New`, `Expansion`, `Contraction`, or `Churn`; anything else fails the build

8 automated data tests currently guard this pipeline.

## CI/CD

Every push to `main` automatically:
1. Spins up a clean environment
2. Installs dbt and connects to Snowflake using encrypted GitHub Secrets
3. Runs the full pipeline (`dbt run`)
4. Runs every data quality test (`dbt test`)

If anything breaks - a bad model, a failed test, a data quality issue - the pipeline fails loudly instead of silently shipping bad data. See [`.github/workflows/dbt_ci.yml`](.github/workflows/dbt_ci.yml) for the full workflow.

## Tech stack

- **dbt Core** - transformation and testing framework
- **Snowflake** - cloud data warehouse
- **GitHub Actions** - CI/CD automation
- **Stripe** - source data (subscriptions and billing events)

## Running it locally

```bash
dbt deps      # install package dependencies
dbt run       # build all models
dbt test      # run all data quality tests
```

Requires a `~/.dbt/profiles.yml` with valid Snowflake credentials (see `dbt_project.yml` for the expected profile name).
