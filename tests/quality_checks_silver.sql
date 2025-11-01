CREATE OR ALTER PROCEDURE silver.test_quality_bronze_to_silver
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @bronze_rows INT, @silver_rows INT,
        @bronze_sales DECIMAL(18,2), @silver_sales DECIMAL(18,2),
        @missing_customer INT, @missing_product INT, @missing_date INT,
        @failed BIT = 0;

    PRINT '===========================================================';
    PRINT '?? Running Bronze → Silver Data Quality Tests';
    PRINT '===========================================================';

    -------------------------------------------------------------------
    -- 1️⃣ Row Count & Total Sales
    -------------------------------------------------------------------
    SELECT 
        @bronze_rows = COUNT(*),
        @bronze_sales = SUM(TRY_CAST(quantity_ordered AS DECIMAL(18,2)) 
                          * TRY_CAST(price_each AS DECIMAL(18,2)))
    FROM bronze.sales_raw;

    SELECT 
        @silver_rows = COUNT(*),
        @silver_sales = SUM(sales_amount)
    FROM silver.fact_sales;

    PRINT CONCAT('🧾 Row Count (Bronze vs Silver):  ', 
                 'Bronze = ', @bronze_rows, 
                 ' | Silver = ', @silver_rows);

    IF @silver_rows < @bronze_rows * 0.8 
        SET @failed = 1;

    PRINT CONCAT('💰 Total Sales (Bronze vs Silver): ',
                 'Bronze = ', FORMAT(@bronze_sales, 'N2'),
                 ' | Silver = ', FORMAT(@silver_sales, 'N2'));

    IF @silver_sales < @bronze_sales * 0.8 
        SET @failed = 1;

    -------------------------------------------------------------------
    -- 2️⃣ Check Missing Dimension References
    -------------------------------------------------------------------
    SELECT 
        @missing_customer = SUM(CASE WHEN c.customer_id IS NULL THEN 1 ELSE 0 END),
        @missing_product = SUM(CASE WHEN p.product_id IS NULL THEN 1 ELSE 0 END),
        @missing_date = SUM(CASE WHEN d.date_id IS NULL THEN 1 ELSE 0 END)
    FROM bronze.sales_raw b
    LEFT JOIN silver.dim_customer c ON c.customer_name = REPLACE(LTRIM(RTRIM(b.customer_name)), '+', '') 
        AND c.phone = dbo.KeepDigits(b.phone)
    LEFT JOIN silver.dim_product p ON p.product_code = LTRIM(RTRIM(b.product_code))
    LEFT JOIN silver.dim_date d ON TRY_CAST(b.order_date AS DATE) = d.full_date;

    PRINT CONCAT('👥 Missing Customer References: ', ISNULL(@missing_customer,0));
    PRINT CONCAT('📦 Missing Product References:  ', ISNULL(@missing_product,0));
    PRINT CONCAT('📅 Missing Date References:     ', ISNULL(@missing_date,0));

    IF @missing_customer > 0 OR @missing_product > 0 OR @missing_date > 0
        SET @failed = 1;

    -------------------------------------------------------------------
    -- 3️⃣ Result Summary
    -------------------------------------------------------------------
    PRINT '-----------------------------------------------------------';
    IF @failed = 1
        PRINT '❌ Quality Check FAILED: Review discrepancies above.';
    ELSE
        PRINT '✅ Quality Check PASSED: Bronze and Silver are consistent.';
    PRINT '===========================================================';
    PRINT CONCAT('Completion time: ', CONVERT(VARCHAR, SYSDATETIME(), 126));
    PRINT '===========================================================';
END;
GO
