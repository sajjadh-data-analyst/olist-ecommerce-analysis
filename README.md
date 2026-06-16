# Olist Brazilian E-Commerce Analysis

## Objective
Analyze 100,000+ real orders from Brazil's largest 
e-commerce marketplace to uncover revenue trends, 
delivery performance, customer satisfaction patterns 
and seller performance.

## Questions Answered
- What is the total revenue and order volume?
- Which product categories generate most revenue?
- Which states have highest customer base?
- Does delivery speed affect customer satisfaction?
- Which sellers perform best?
- What payment methods do customers prefer?

## Data Cleaning
- Removed encoding issues from CSV files
- Handled NULL values with COALESCE
- Filtered continent IS NOT NULL to avoid double counting
- Added product category translation from Portuguese to English

## EDA Chapters
- Chapter 1: Business Overview — revenue, orders, customers
- Chapter 2: Revenue Trends — monthly and MOM growth
- Chapter 3: Product Analysis — top categories by revenue
- Chapter 4: Geographic Analysis — revenue by state and city
- Chapter 5: Delivery Performance — on time vs late
- Chapter 6: Customer Satisfaction — review scores
- Chapter 7: Seller Performance — top sellers

## Key Findings
- Fast deliveries score 4.41 stars vs 3.65 for slow
- Credit card dominates with 76K+ transactions
- Olist grew from R$138K to R$1M+ monthly revenue in 2017
- 96.5% of orders successfully delivered

## Tools
PostgreSQL · Power BI · Excel
