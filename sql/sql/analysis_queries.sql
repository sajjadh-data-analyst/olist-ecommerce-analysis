-- =============================================
-- OLIST E-COMMERCE ANALYSIS QUERIES
-- Author: Sajjad Hussain
-- Tools: PostgreSQL
-- Dataset: Olist Brazilian E-Commerce Public Dataset
-- =============================================


-- ============================================
-- CHAPTER 1 — Business Overview
-- ============================================

-- Row counts for all tables
SELECT 'customers' AS table_name, COUNT(*) FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation;

-- Total Revenue
SELECT SUM(payment_value) AS total_revenue
FROM order_payments;

-- Total Orders
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM orders;

-- Total Customers
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM customers;

-- Total Sellers
SELECT COUNT(DISTINCT seller_id) AS total_sellers
FROM sellers;

-- Average Order Value
WITH order_totals AS (
    SELECT order_id, SUM(payment_value) AS order_total
    FROM order_payments
    GROUP BY order_id
)
SELECT ROUND(AVG(order_total), 2) AS avg_order_value
FROM order_totals;


-- ============================================
-- CHAPTER 2 — Revenue & Time Trends
-- ============================================

-- Total Revenue by Year
SELECT 
    EXTRACT(YEAR FROM order_purchase_timestamp) AS years,
    SUM(payment_value) AS revenue
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY years
ORDER BY years;

-- Total Revenue by Month and Year
SELECT 
    EXTRACT(MONTH FROM order_purchase_timestamp) AS months,
    EXTRACT(YEAR FROM order_purchase_timestamp) AS years,
    SUM(payment_value) AS revenue
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY months, years
ORDER BY years, months;

-- Month Over Month Revenue Growth
WITH current_month AS (
    SELECT 
        EXTRACT(MONTH FROM order_purchase_timestamp) AS months,
        EXTRACT(YEAR FROM order_purchase_timestamp) AS years,
        SUM(payment_value) AS current_month_revenue
    FROM orders o
    JOIN order_payments op ON o.order_id = op.order_id
    GROUP BY months, years
),
previous_month AS (
    SELECT *,
        LAG(current_month_revenue) OVER (ORDER BY years, months) AS previous_month_revenue
    FROM current_month
)
SELECT 
    months,
    years,
    current_month_revenue,
    previous_month_revenue,
    ROUND(((current_month_revenue - previous_month_revenue) / previous_month_revenue * 100), 2) AS MOM_revenue
FROM previous_month;


-- ============================================
-- CHAPTER 3 — Product Analysis
-- ============================================

-- Top 10 Categories by Revenue (English)
SELECT 
    t.product_category_name_english,
    SUM(price) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_translation t ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
GROUP BY t.product_category_name_english
ORDER BY revenue DESC
LIMIT 10;

-- Top 10 Categories by Number of Orders (English)
SELECT 
    t.product_category_name_english,
    COUNT(order_id) AS number_of_orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_translation t ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY number_of_orders DESC
LIMIT 10;

-- Average Product Price by Category (English)
SELECT 
    t.product_category_name_english,
    ROUND(AVG(price), 2) AS avg_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_translation t ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
GROUP BY t.product_category_name_english
ORDER BY avg_price DESC
LIMIT 10;


-- ============================================
-- CHAPTER 4 — Geographic Analysis
-- ============================================

-- Revenue by Customer State
SELECT 
    customer_state,
    SUM(payment_value) AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY customer_state
ORDER BY revenue DESC;

-- Top 10 Cities by Number of Orders
SELECT 
    customer_city,
    COUNT(order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY customer_city
ORDER BY total_orders DESC
LIMIT 10;

-- Customers by State
SELECT 
    customer_state,
    COUNT(customer_id) AS total_customers
FROM customers
GROUP BY customer_state
ORDER BY total_customers DESC;


-- ============================================
-- CHAPTER 5 — Delivery Performance
-- ============================================

-- Average Delivery Time in Days
SELECT 
    AVG(EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp))) AS avg_delivery_time
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- On Time vs Late Deliveries
SELECT 
    COUNT(*) AS total_delivered,
    SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) AS on_time,
    SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_delivery,
    ROUND(SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_percentage,
    ROUND(SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS on_time_percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


-- ============================================
-- CHAPTER 6 — Customer Satisfaction
-- ============================================

-- Overall Average Review Score
SELECT ROUND(AVG(review_score), 2) AS avg_review_score
FROM order_reviews;

-- Review Score Distribution
SELECT 
    review_score,
    COUNT(review_score) AS total_reviews
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- Delivery Time vs Review Score
WITH delivery_stats AS (
    SELECT 
        review_score,
        EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)) AS delivery_time,
        CASE 
            WHEN EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)) <= 7 THEN 'Fast (0-7 days)'
            WHEN EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)) BETWEEN 8 AND 14 THEN 'Normal (8-14 days)'
            ELSE 'Slow (15+ days)'
        END AS delivery_group
    FROM orders o
    JOIN order_reviews orr ON o.order_id = orr.order_id
    WHERE order_delivered_customer_date IS NOT NULL
)
SELECT 
    delivery_group,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    COUNT(*) AS total_orders
FROM delivery_stats
GROUP BY delivery_group
ORDER BY avg_review_score DESC;


-- ============================================
-- CHAPTER 7 — Seller Performance
-- ============================================

-- Top 10 Sellers by Revenue
SELECT 
    seller_id,
    SUM(price) AS revenue
FROM order_items
GROUP BY seller_id
ORDER BY revenue DESC
LIMIT 10;

-- Top 10 Sellers by Number of Orders
SELECT 
    seller_id,
    COUNT(order_id) AS total_orders
FROM order_items
GROUP BY seller_id
ORDER BY total_orders DESC
LIMIT 10;

-- Average Review Score per Seller
SELECT 
    seller_id,
    ROUND(AVG(review_score), 2) AS avg_review
FROM order_items oi
JOIN order_reviews orv ON oi.order_id = orv.order_id
GROUP BY seller_id
ORDER BY avg_review DESC;


-- ============================================
-- BONUS — Payment & Order Status
-- ============================================

-- Revenue and Count by Payment Type
SELECT 
    payment_type,
    SUM(payment_value) AS revenue,
    COUNT(payment_type) AS count_of_payment_type
FROM order_payments
GROUP BY payment_type
ORDER BY revenue DESC;

-- Order Count by Status
SELECT 
    order_status,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;
