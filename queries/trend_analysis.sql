-- queries/trend_analysis.sql

-- 1) 7-day and 30-day moving average of daily revenue
WITH daily_revenue AS (
    SELECT
        o.order_date AS order_day,
        SUM(oi.quantity * oi.unit_price) AS daily_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY o.order_date
)
SELECT
    order_day,
    daily_revenue,
    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY order_day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS revenue_ma_7d,
    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY order_day
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS revenue_ma_30d
FROM daily_revenue
ORDER BY order_day;


-- 2) 7-day moving average of daily order count
WITH daily_orders AS (
    SELECT
        o.order_date AS order_day,
        COUNT(DISTINCT o.order_id) AS daily_order_count
    FROM orders o
    WHERE o.status = 'completed'
    GROUP BY o.order_date
)
SELECT
    order_day,
    daily_order_count,
    ROUND(
        AVG(daily_order_count) OVER (
            ORDER BY order_day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS order_count_ma_7d
FROM daily_orders
ORDER BY order_day;


-- 3) Combined daily trend view: raw revenue + raw orders + moving averages
WITH daily_metrics AS (
    SELECT
        o.order_date AS order_day,
        SUM(oi.quantity * oi.unit_price) AS daily_revenue,
        COUNT(DISTINCT o.order_id) AS daily_order_count
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY o.order_date
)
SELECT
    order_day,
    daily_revenue,
    daily_order_count,
    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY order_day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS revenue_ma_7d,
    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY order_day
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS revenue_ma_30d,
    ROUND(
        AVG(daily_order_count) OVER (
            ORDER BY order_day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS order_count_ma_7d
FROM daily_metrics
ORDER BY order_day;