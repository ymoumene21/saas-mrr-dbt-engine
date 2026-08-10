# SaaS MRR Analytics Engine

A dbt project that turns raw Stripe subscription data into tested, reliable MRR (Monthly Recurring Revenue) metrics — the kind of pipeline a SaaS company's finance and growth teams would actually rely on to track revenue movements over time.

[![dbt CI Pipeline](https://github.com/ymoumene21/saas-mrr-dbt-engine/actions/workflows/dbt_ci.yml/badge.svg)](https://github.com/ymoumene21/saas-mrr-dbt-engine/actions/workflows/dbt_ci.yml)

## The problem this solves

Raw subscription data only tells you the *current* state of a subscription - active, cancelled, etc. It doesn't tell you *how revenue changed over time*: which customers are new, which upgraded, which downgraded, and which churned. Answering that requires tracking subscription status changes historically, not just querying the latest snapshot.

This project builds that history from scratch and classifies every change into one of four standard SaaS revenue movement types: **New, Expansion, Contraction, Churn**.

## Pipeline architecture
