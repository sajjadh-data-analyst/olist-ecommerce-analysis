-- =============================================
-- OLIST E-COMMERCE VIEWS
-- Author: Sajjad Hussain
-- Tools: PostgreSQL
-- Dataset: Olist Brazilian E-Commerce Public Dataset
-- =============================================


-- ============================================
-- CHAPTER 1 — Business Overview
-- ============================================

CREATE VIEW vw_business_overview AS
SELECT
    SUM(oi.price) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    COUNT(DISTINCT oi.seller_id) AS total_sellers
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id;


-- ============================================
-- CHAPTER 2 — Revenue & Time Trends
-- ============================================

CREATE VIEW vw_monthly_revenue AS
SELECT
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS months,
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS years,
    SUM(op.payment_value) AS monthly_revenue
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY
    EXTRACT(MONTH FROM o.order_purchase_timestamp),
    EXTRACT(YEAR FROM o.order_purchase_timestamp);


CREATE VIEW vw_mom_growth AS
WITH current_month AS (
    SELECT
        EXTRACT(MONTH FROM o.order_purchase_timestamp) AS months,
        EXTRACT(YEAR FROM o.order_purchase_timestamp) AS years,
        SUM(op.payment_value) AS current_month_revenue
    FROM orders o
    JOIN order_payments op ON o.order_id = op.order_id
    GROUP BY
        EXTRACT(MONTH FROM o.order_purchase_timestamp),
        EXTRACT(YEAR FROM o.order_purchase_timestamp)
),
previous_month AS (
    SELECT
        months,
        years,
        current_month_revenue,
        LAG(current_month_revenue) OVER (ORDER BY years, months) AS previous_month_revenue
    FROM current_month
)
SELECT
    months,
    years,
    current_month_revenue,
    previous_month_revenue,
    ROUND(((current_month_revenue - previous_month_revenue) / previous_month_revenue * 100), 2) AS mom_revenue
FROM previous_month;


-- ============================================
-- CHAPTER 3 — Product Analysis
-- ============================================

CREATE VIEW vw_category_revenue AS
SELECT
    t.product_category_name_english,
    SUM(oi.price) AS revenue_generated
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN product_category_translation t ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english;


CREATE VIEW vw_category_orders AS
SELECT
    t.product_category_name_english,
    COUNT(oi.order_id) AS number_of_orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_translation t ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english;


CREATE VIEW vw_category_avg_price AS
SELECT
    t.product_category_name_english,
    ROUND(AVG(oi.price), 2) AS avg_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_translation t ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english;


-- ============================================
-- CHAPTER 4 — Geographic Analysis
-- ============================================

CREATE VIEW vw_revenue_by_state AS
SELECT
    c.customer_state,
    SUM(op.payment_value) AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY c.customer_state;


CREATE VIEW vw_orders_by_city AS
SELECT
    c.customer_city,
    COUNT(o.order_id) AS number_of_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_city;


CREATE VIEW vw_customers_by_state AS
SELECT
    customer_state,
    COUNT(DISTINCT customer_id) AS number_of_customers
FROM customers c
GROUP BY customer_state;


-- ============================================
-- CHAPTER 5 — Delivery Performance
-- ============================================

CREATE VIEW vw_avg_delivery_time AS
SELECT
    ROUND(AVG(EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp))), 1) AS avg_delivery_time
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


CREATE VIEW vw_delivery_performance AS
SELECT
    COUNT(*) AS total_delivered,
    SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) AS on_time,
    SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_delivery,
    ROUND(SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_percentage,
    ROUND(SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS on_time_percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


CREATE VIEW vw_delivery_vs_satisfaction AS
WITH delivery_stats AS (
    SELECT
        orr.review_score,
        EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) AS delivery_time,
        CASE
            WHEN EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) <= 7 THEN 'Fast (0-7 days)'
            WHEN EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) BETWEEN 8 AND 14 THEN 'Normal (8-14 days)'
            ELSE 'Slow (15+ days)'
        END AS delivery_group
    FROM orders o
    JOIN order_reviews orr ON o.order_id = orr.order_id
    WHERE o.order_delivered_customer_date IS NOT NULL
)
SELECT
    delivery_group,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    COUNT(*) AS total_orders
FROM delivery_stats
GROUP BY delivery_group;


-- ============================================
-- CHAPTER 6 — Customer Satisfaction
-- ============================================

CREATE VIEW vw_avg_review_score AS
SELECT ROUND(AVG(review_score), 2) AS avg_review_score
FROM order_reviews;


CREATE VIEW vw_review_distribution AS
SELECT
    review_score,
    COUNT(review_score) AS review_distribution
FROM order_reviews
GROUP BY review_score;


-- ============================================
-- CHAPTER 7 — Seller Performance
-- ============================================

CREATE VIEW vw_seller_revenue AS
SELECT
    seller_id,
    SUM(price) AS revenue
FROM order_items
GROUP BY seller_id;


CREATE VIEW vw_seller_orders AS
SELECT
    seller_id,
    COUNT(DISTINCT order_id) AS number_of_orders
FROM order_items
GROUP BY seller_id;


CREATE VIEW vw_seller_ratings AS
SELECT
    oi.seller_id,
    ROUND(AVG(orr.review_score), 2) AS avg_review_score
FROM order_items oi
JOIN order_reviews orr ON oi.order_id = orr.order_id
GROUP BY oi.seller_id;


-- ============================================
-- BONUS — Payment & Order Status
-- ============================================

CREATE VIEW vw_payment_type AS
SELECT
    payment_type,
    COUNT(order_id) AS total_orders,
    SUM(payment_value) AS total_transaction
FROM order_payments
GROUP BY payment_type;


CREATE VIEW vw_order_status AS
SELECT
    order_status,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY order_status;
