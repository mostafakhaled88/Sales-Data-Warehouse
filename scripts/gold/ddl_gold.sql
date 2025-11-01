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


