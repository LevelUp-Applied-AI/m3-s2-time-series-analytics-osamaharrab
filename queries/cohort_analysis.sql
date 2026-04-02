WITH ranked_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        o.status,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date
        ) AS rn
    FROM orders o
),
first_purchases AS (
    SELECT
        customer_id,
        order_id AS first_order_id,
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
        o.order_id,
        o.order_date
    FROM first_purchases fp
    JOIN orders o
        ON fp.customer_id = o.customer_id
    WHERE o.order_date > fp.first_purchase_date
),
retention_flags AS (
    SELECT
        fp.customer_id,
        fp.cohort_month,
        MAX(CASE WHEN ro.order_date <= fp.first_purchase_date + INTERVAL '30 days' THEN 1 ELSE 0 END) AS retained_30,
        MAX(CASE WHEN ro.order_date <= fp.first_purchase_date + INTERVAL '60 days' THEN 1 ELSE 0 END) AS retained_60,
        MAX(CASE WHEN ro.order_date <= fp.first_purchase_date + INTERVAL '90 days' THEN 1 ELSE 0 END) AS retained_90
    FROM first_purchases fp
    LEFT JOIN repeat_orders ro
        ON fp.customer_id = ro.customer_id
    GROUP BY
        fp.customer_id,
        fp.cohort_month,
        fp.first_purchase_date
),
cohort_summary AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size,
        SUM(retained_30) AS retained_customers_30,
        SUM(retained_60) AS retained_customers_60,
        SUM(retained_90) AS retained_customers_90,
        ROUND(100.0 * SUM(retained_30) / COUNT(*), 2) AS retention_rate_30,
        ROUND(100.0 * SUM(retained_60) / COUNT(*), 2) AS retention_rate_60,
        ROUND(100.0 * SUM(retained_90) / COUNT(*), 2) AS retention_rate_90
    FROM retention_flags
    GROUP BY cohort_month
)
SELECT *
FROM cohort_summary
ORDER BY cohort_month;