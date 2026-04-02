-- queries/growth_analysis.sql

-- 1) Month-over-month revenue growth rate
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month_start,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    month_start,
    revenue,
    LAG(revenue) OVER (ORDER BY month_start) AS previous_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month_start))
        / NULLIF(LAG(revenue) OVER (ORDER BY month_start), 0),
        2
    ) AS mom_revenue_growth_rate
FROM monthly_revenue
ORDER BY month_start;


-- 2) Month-over-month order volume growth rate
WITH monthly_orders AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month_start,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    WHERE o.status = 'completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    month_start,
    order_count,
    LAG(order_count) OVER (ORDER BY month_start) AS previous_month_order_count,
    ROUND(
        100.0 * (order_count - LAG(order_count) OVER (ORDER BY month_start))
        / NULLIF(LAG(order_count) OVER (ORDER BY month_start), 0),
        2
    ) AS mom_order_growth_rate
FROM monthly_orders
ORDER BY month_start;


-- 3) Quarter-over-quarter revenue growth rate
WITH quarterly_revenue AS (
    SELECT
        DATE_TRUNC('quarter', o.order_date) AS quarter_start,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY DATE_TRUNC('quarter', o.order_date)
)
SELECT
    quarter_start,
    revenue,
    LAG(revenue) OVER (ORDER BY quarter_start) AS previous_quarter_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY quarter_start))
        / NULLIF(LAG(revenue) OVER (ORDER BY quarter_start), 0),
        2
    ) AS qoq_revenue_growth_rate
FROM quarterly_revenue
ORDER BY quarter_start;


-- 4) Monthly revenue drivers: customers, orders, AOV
WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month_start,
        SUM(oi.quantity * oi.unit_price) AS revenue,
        COUNT(DISTINCT o.order_id) AS order_count,
        COUNT(DISTINCT o.customer_id) AS customer_count
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    month_start,
    revenue,
    order_count,
    customer_count,
    ROUND(revenue / NULLIF(order_count, 0), 2) AS avg_order_value,
    LAG(revenue) OVER (ORDER BY month_start) AS prev_revenue,
    LAG(order_count) OVER (ORDER BY month_start) AS prev_order_count,
    LAG(customer_count) OVER (ORDER BY month_start) AS prev_customer_count,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month_start))
        / NULLIF(LAG(revenue) OVER (ORDER BY month_start), 0),
        2
    ) AS revenue_growth_pct,
    ROUND(
        100.0 * (order_count - LAG(order_count) OVER (ORDER BY month_start))
        / NULLIF(LAG(order_count) OVER (ORDER BY month_start), 0),
        2
    ) AS order_growth_pct,
    ROUND(
        100.0 * (customer_count - LAG(customer_count) OVER (ORDER BY month_start))
        / NULLIF(LAG(customer_count) OVER (ORDER BY month_start), 0),
        2
    ) AS customer_growth_pct
FROM monthly_metrics
ORDER BY month_start;


-- 5) Monthly category revenue to help explain growth by mix
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
)
SELECT
    month_start,
    category,
    category_revenue,
    LAG(category_revenue) OVER (
        PARTITION BY category
        ORDER BY month_start
    ) AS previous_month_category_revenue,
    ROUND(
        100.0 * (
            category_revenue
            - LAG(category_revenue) OVER (
                PARTITION BY category
                ORDER BY month_start
            )
        )
        / NULLIF(
            LAG(category_revenue) OVER (
                PARTITION BY category
                ORDER BY month_start
            ),
            0
        ),
        2
    ) AS mom_category_growth_rate
FROM monthly_category_revenue
ORDER BY month_start, category;