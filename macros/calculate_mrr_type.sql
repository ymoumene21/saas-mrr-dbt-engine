{#
  This macro takes in column names (as text) and returns a CASE WHEN
  expression that classifies an MRR movement.
  Because it takes column names as parameters, we can reuse it on any
  model that has a "current" and "previous" MRR column.
#}

{% macro calculate_mrr_type(current_mrr_column, previous_mrr_column, status_column) %}
    case
        -- No previous value exists yet = this is the first time we've seen this subscription
        when {{ previous_mrr_column }} is null then 'New'

        -- Subscription was cancelled = churned, regardless of MRR delta
        when {{ status_column }} = 'cancelled' then 'Churn'

        -- MRR went up = customer expanded their plan
        when {{ current_mrr_column }} > {{ previous_mrr_column }} then 'Expansion'

        -- MRR went down = customer downgraded their plan
        when {{ current_mrr_column }} < {{ previous_mrr_column }} then 'Contraction'

        -- MRR is unchanged = no movement to report
        else 'Unchanged'
    end
{% endmacro %}