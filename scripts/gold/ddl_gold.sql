CREATE OR ALTER VIEW gold.vw_sales_performance AS
SELECT
   
    -- Sales facts
    fs.order_number,
    fs.status,
    fs.quantity_ordered,
    fs.price_each,
    fs.sales_amount,
    fs.deal_size,

	 -- Date dimensions
    d.full_date,
    d.year_number,
    d.month_number,
    d.month_name,
    d.quarter_name,

    -- Customer dimensions
    c.customer_name,
    c.country,
    c.territory,

    -- Product dimensions
    p.product_code,
    p.product_line


   
FROM silver.fact_sales fs
LEFT JOIN silver.dim_date d 
    ON fs.date_id = d.date_id
LEFT JOIN silver.dim_customer c 
    ON fs.customer_id = c.customer_id
LEFT JOIN silver.dim_product p 
    ON fs.product_id = p.product_id;

CREATE OR ALTER VIEW gold.vw_sales_summary AS
SELECT
    d.year_number,
    d.month_number,
    p.product_line,
    SUM(fs.quantity_ordered) AS total_quantity,
    SUM(fs.sales_amount) AS total_sales,
    ROUND(AVG(fs.price_each), 2) AS avg_unit_price
FROM silver.fact_sales fs
JOIN silver.dim_date d 
    ON fs.date_id = d.date_id
JOIN silver.dim_product p 
    ON fs.product_id = p.product_id
GROUP BY
    d.year_number,
    d.month_number,
    p.product_line;
GO

CREATE OR ALTER VIEW gold.vw_customer_insights AS
SELECT
    c.customer_id,
    c.customer_name,
    c.country,
    c.territory,
    COUNT(DISTINCT fs.order_number) AS total_orders,
    SUM(fs.sales_amount) AS total_spent,
    SUM(fs.quantity_ordered) AS total_items_purchased,
    ROUND(AVG(fs.price_each), 2) AS avg_price_per_item
FROM silver.fact_sales fs
JOIN silver.dim_customer c 
    ON fs.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.customer_name,
    c.country,
    c.territory;
GO

CREATE OR ALTER VIEW gold.vw_regional_performance AS
SELECT
    c.country,
    c.territory,
    d.year_number,
    d.month_number,
    SUM(fs.sales_amount) AS total_sales,
    SUM(fs.quantity_ordered) AS total_quantity,
    COUNT(DISTINCT fs.customer_id) AS active_customers
FROM silver.fact_sales fs
JOIN silver.dim_customer c 
    ON fs.customer_id = c.customer_id
JOIN silver.dim_date d 
    ON fs.date_id = d.date_id
GROUP BY
    c.country,
    c.territory,
    d.year_number,
    d.month_number;
GO


