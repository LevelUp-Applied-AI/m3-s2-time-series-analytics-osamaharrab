-- queries/combined_analysis.sql

-- 1) Monthly revenue by segment with growth rate and running total
WITH monthly_segment_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month_start,
        c.segment,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY DATE_TRUNC('month', o.order_date), c.segment
)
SELECT
    month_start,
    segment,
    revenue,
    LAG(revenue) OVER (
        PARTITION BY segment
        ORDER BY month_start
    ) AS previous_month_revenue,
    ROUND(
        100.0 * (
            revenue - LAG(revenue) OVER (
                PARTITION BY segment
                ORDER BY month_start
            )
        )
        / NULLIF(
            LAG(revenue) OVER (
                PARTITION BY segment
                ORDER BY month_start
            ),
            0
        ),
        2
    ) AS mom_growth_rate,
    SUM(revenue) OVER (
        PARTITION BY segment
        ORDER BY month_start
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_revenue
FROM monthly_segment_revenue
ORDER BY month_start, segment;


-- 2) Category revenue share with 3-month moving average trend
WITH monthly_category_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month_start,
        p.category,
        SUM(oi.quantity * oi.unit_price) AS category_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.status = 'completed'
    GROUP BY DATE_TRUNC('month', o.order_date), p.category
),
category_share_base AS (
    SELECT
        month_start,
        category,
        category_revenue,
        SUM(category_revenue) OVER (
            PARTITION BY month_start
        ) AS total_month_revenue
    FROM monthly_category_revenue
)
SELECT
    month_start,
    category,
    category_revenue,
    ROUND(
        100.0 * category_revenue / NULLIF(total_month_revenue, 0),
        2
    ) AS revenue_share_pct,
    ROUND(
        AVG(category_revenue) OVER (
            PARTITION BY category
            ORDER BY month_start
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS category_revenue_ma_3m
FROM category_share_base
ORDER BY month_start, category;


-- 3) Cohort retention with period-over-period change
WITH ranked_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date
        ) AS rn
    FROM orders o
    WHERE o.status = 'completed'
),
first_purchases AS (
    SELECT
        customer_id,
        order_date AS first_purchase_date,
        DATE_TRUNC('month', order_date) AS cohort_month
    FROM ranked_orders
    WHERE rn = 1
),
repeat_orders AS (
    SELECT
        fp.customer_id,
        fp.cohort_month,
        fp.first_purchase_date,
        o.order_date
    FROM first_purchases fp
    JOIN orders o
        ON fp.customer_id = o.customer_id
    WHERE o.status = 'completed'
      AND o.order_date > fp.first_purchase_date
),
retention_flags AS (
    SELECT
        fp.customer_id,
        fp.cohort_month,
        MAX(
            CASE
                WHEN ro.order_date <= fp.first_purchase_date + INTERVAL '90 days'
                THEN 1 ELSE 0
            END
        ) AS retained_90
    FROM first_purchases fp
    LEFT JOIN repeat_orders ro
        ON fp.customer_id = ro.customer_id
    GROUP BY
        fp.customer_id,
        fp.cohort_month,
        fp.first_purchase_date
),
cohort_retention AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size,
        SUM(retained_90) AS retained_customers_90,
        ROUND(100.0 * SUM(retained_90) / COUNT(*), 2) AS retention_rate_90
    FROM retention_flags
    GROUP BY cohort_month
)
SELECT
    cohort_month,
    cohort_size,
    retained_customers_90,
    retention_rate_90,
    LAG(retention_rate_90) OVER (
        ORDER BY cohort_month
    ) AS previous_cohort_retention_rate_90,
    ROUND(
        retention_rate_90 - LAG(retention_rate_90) OVER (
            ORDER BY cohort_month
        ),
        2
    ) AS retention_rate_change
FROM cohort_retention
ORDER BY cohort_month;