"""
generate_raw_data.py
--------------------
Creates realistic, fake Stripe-style raw data for the SaaS MRR Analytics Engine.

Why a script instead of Mockaroo?
  - Mockaroo gives random rows with no history. A real SaaS business has
    customers who sign up, upgrade, downgrade and cancel over many months.
  - A fixed random "seed" makes the output identical every run
    (idempotent: run it 100 times, get the same files).

Outputs (in data/raw/):
  raw_users.csv                  one row per customer
  raw_subscriptions.csv          CURRENT state of each subscription (like Stripe today)
  raw_subscription_events.csv    FULL history of every change (used from Day 12)

Run from the project root:
  python scripts/generate_raw_data.py
"""

import csv
import random
import uuid
from datetime import datetime, timedelta
from pathlib import Path

SEED = 42                      # change this and you get a different (but still repeatable) dataset
START = datetime(2025, 1, 1)   # first month of the business
N_MONTHS = 21                  # Jan 2025 -> Sep 2026

# Plan catalogue: plan name -> possible monthly prices (price tiers / seat counts)
PLANS = {
    "Basic":      [29, 49],
    "Pro":        [99, 149, 199],
    "Enterprise": [399, 499],
}
PLAN_ORDER = ["Basic", "Pro", "Enterprise"]

# Monthly probabilities for an ACTIVE subscription
P_UPGRADE = 0.04
P_DOWNGRADE = 0.015
P_CHURN = 0.025

# Slightly messy country values on purpose: stg_users cleans them with upper(trim())
COUNTRIES = ["United Kingdom", "united kingdom ", "France", "Germany",
             "Canada", " canada", "Algeria", "United States", "Spain", "Netherlands"]

rng = random.Random(SEED)
OUT = Path(__file__).resolve().parent.parent / "data" / "raw"


def new_id() -> str:
    """Deterministic UUID (same seed -> same IDs)."""
    return str(uuid.UUID(int=rng.getrandbits(128), version=4))


def month_start(i: int) -> datetime:
    """First day of month number i (0 = START)."""
    y, m = divmod(START.month - 1 + i, 12)
    return datetime(START.year + y, m + 1, 1)


def random_moment(i: int) -> datetime:
    """A random timestamp inside month i."""
    return month_start(i) + timedelta(days=rng.randint(0, 27), hours=rng.randint(8, 19),
                                      minutes=rng.randint(0, 59))


def fmt(ts: datetime) -> str:
    return ts.strftime("%Y-%m-%d %H:%M:%S")


users, events, current = [], [], {}

for month in range(N_MONTHS):
    # 1) New customers: the business grows, so more sign-ups each month
    for _ in range(rng.randint(12, 18) + month):
        user_id, sub_id = new_id(), new_id()
        signed_up = random_moment(month)
        plan = rng.choices(PLAN_ORDER, weights=[55, 35, 10])[0]
        price = rng.choice(PLANS[plan])
        users.append({"user_id": user_id, "country": rng.choice(COUNTRIES),
                      "signup_date": fmt(signed_up)})
        sub = {"subscription_id": sub_id, "user_id": user_id, "plan_name": plan,
               "mrr_amount": price, "status": "active", "created_at": fmt(signed_up)}
        current[sub_id] = sub
        events.append({**sub, "event_type": "created", "event_at": fmt(signed_up)})

    # 2) Existing active customers may upgrade, downgrade or cancel
    for sub_id, sub in current.items():
        if sub["status"] != "active" or sub["created_at"] >= fmt(month_start(month)):
            continue  # skip cancelled subs and ones created this month
        roll = rng.random()
        idx = PLAN_ORDER.index(sub["plan_name"])
        if roll < P_CHURN:
            sub["status"], event_type = "cancelled", "cancelled"
        elif roll < P_CHURN + P_UPGRADE:
            if idx < 2 and rng.random() < 0.6:          # move up a plan...
                sub["plan_name"] = PLAN_ORDER[idx + 1]
            higher = [p for p in PLANS[sub["plan_name"]] if p > sub["mrr_amount"]]
            if not higher:
                continue                                  # already at top price
            sub["mrr_amount"], event_type = rng.choice(higher), "upgraded"
        elif roll < P_CHURN + P_UPGRADE + P_DOWNGRADE:
            if idx > 0 and rng.random() < 0.6:          # ...or down a plan
                sub["plan_name"] = PLAN_ORDER[idx - 1]
            lower = [p for p in PLANS[sub["plan_name"]] if p < sub["mrr_amount"]]
            if not lower:
                continue
            sub["mrr_amount"], event_type = rng.choice(lower), "downgraded"
        else:
            continue                                      # no change this month
        events.append({**sub, "event_type": event_type, "event_at": fmt(random_moment(month))})


def write(name: str, rows: list, cols: list) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    with open(OUT / name, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)
    print(f"wrote {len(rows):>5} rows -> data/raw/{name}")


sub_cols = ["subscription_id", "user_id", "plan_name", "mrr_amount", "status", "created_at"]
write("raw_users.csv", users, ["user_id", "country", "signup_date"])
write("raw_subscriptions.csv", list(current.values()), sub_cols)
write("raw_subscription_events.csv", events, sub_cols + ["event_type", "event_at"])
