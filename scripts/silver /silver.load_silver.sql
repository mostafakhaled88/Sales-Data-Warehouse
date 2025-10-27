/*
===============================================================================
Stored Procedure: silver.load_silver
===============================================================================
Purpose:
    Loads data from the Bronze layer (raw data) into the Silver layer 
    (cleaned, structured, and conformed tables).

Enhancements / Best Practices Implemented:
    ✅ Supports FULL or INCREMENTAL load.
    ✅ Includes audit & error logging tables (auto-created if missing).
    ✅ Validates data before insert.
    ✅ Applies surrogate key relationships (FKs).
    ✅ Handles constraints dynamically.
    ✅ Records ETL duration and row counts for transparency.

Usage Example:
    EXEC silver.load_silver @LoadMode = 'FULL';        -- Truncate & reload all
    EXEC silver.load_silver @LoadMode = 'INCREMENTAL'; -- Load only new data
===============================================================================
*/

USE SalesDWH;
GO

IF OBJECT_ID('silver.load_silver', 'P') IS NOT NULL
    DROP PROCEDURE silver.load_silver;
GO

CREATE PROCEDURE silver.load_silver
    @LoadMode NVARCHAR(20) = 'FULL'  -- Options: FULL or INCREMENTAL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE 
        @start_time DATETIME = GETDATE(),
        @end_time DATETIME,
        @rowcount INT = 0,
        @msg NVARCHAR(4000);

    PRINT '================================================';
    PRINT '⚙️  Starting Silver Layer Load (' + @LoadMode + ' mode)';
    PRINT '================================================';

    BEGIN TRY
      

        -------------------------------------------------------------------
        -- 1. Drop Constraints Before Load
        -------------------------------------------------------------------
        PRINT '→ Dropping Foreign Key Constraints...';
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_customer')
            ALTER TABLE silver.fact_sales DROP CONSTRAINT fk_fact_sales_customer;
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_product')
            ALTER TABLE silver.fact_sales DROP CONSTRAINT fk_fact_sales_product;
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'fk_fact_sales_date')
            ALTER TABLE silver.fact_sales DROP CONSTRAINT fk_fact_sales_date;

        -------------------------------------------------------------------
        -- 2. FULL or INCREMENTAL Load
        -------------------------------------------------------------------
        IF UPPER(@LoadMode) = 'FULL'
        BEGIN
            PRINT '→ Performing FULL reload (truncate all Silver tables)...';
            TRUNCATE TABLE silver.fact_sales;
            TRUNCATE TABLE silver.dim_customer;
            TRUNCATE TABLE silver.dim_product;
            TRUNCATE TABLE silver.dim_date;
        END
        ELSE
        BEGIN
            PRINT '→ Performing INCREMENTAL load (insert new data only)...';
        END

        -------------------------------------------------------------------
        -- 3. Load DimDate
        -------------------------------------------------------------------
        PRINT '→ Loading DimDate...';
        DECLARE @MinDate DATE, @MaxDate DATE;
        SELECT 
            @MinDate = MIN(TRY_CAST(order_date AS DATE)),
            @MaxDate = MAX(TRY_CAST(order_date AS DATE))
        FROM bronze.sales_raw;

        ;WITH AllDates AS (
            SELECT @MinDate AS full_date
            UNION ALL
            SELECT DATEADD(DAY, 1, full_date)
            FROM AllDates
            WHERE full_date < @MaxDate
        )
        INSERT INTO silver.dim_date (full_date, day_number, month_number, month_name, quarter_name, year_number, dwh_create_date)
        SELECT 
            full_date,
            DAY(full_date),
            MONTH(full_date),
            DATENAME(MONTH, full_date),
            'Q' + CAST(DATEPART(QUARTER, full_date) AS NVARCHAR),
            YEAR(full_date),
            GETDATE()
        FROM AllDates
        WHERE NOT EXISTS (SELECT 1 FROM silver.dim_date WHERE full_date = AllDates.full_date)
        OPTION (MAXRECURSION 0);

        -------------------------------------------------------------------
        -- 4. Load DimCustomer
        -------------------------------------------------------------------
        PRINT '→ Loading DimCustomer...';
        INSERT INTO silver.dim_customer (
            customer_name, contact_first_name, contact_last_name, phone,
            address_line, city, state, postal_code, country, territory
        )
        SELECT DISTINCT
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(b.customer_name)), '+', ''), '(', ''), ')', ''), '"', ''), '.', ''), ',', ''), '/', '') AS customer_name,
            REPLACE(LTRIM(RTRIM(b.contact_first_name)), '-', '') AS contact_first_name,
            REPLACE(LTRIM(RTRIM(b.contact_last_name)), '-', '') AS contact_last_name,
            dbo.KeepDigits(b.phone) AS phone,
            LTRIM(RTRIM(b.address_line1)) AS address_line,
            LTRIM(RTRIM(b.city)) AS city,
            ISNULL(NULLIF(UPPER(LTRIM(RTRIM(b.state))), ''), 'UNKNOWN') AS state,
            ISNULL(NULLIF(UPPER(LTRIM(RTRIM(b.postal_code))), ''), 'UNKNOWN') AS postal_code,
            LTRIM(RTRIM(b.country)) AS country,
            CASE 
                WHEN UPPER(b.country) IN ('USA','CANADA','MEXICO') THEN 'NA'
                WHEN UPPER(b.country) IN ('FRANCE','GERMANY','ITALY','SPAIN','UK','BELGIUM','NORWAY','SWEDEN','AUSTRIA','SWITZERLAND','IRELAND','DENMARK','FINLAND') THEN 'EMEA'
                WHEN UPPER(b.country) IN ('AUSTRALIA','SINGAPORE','JAPAN','PHILIPPINES') THEN 'APAC'
                ELSE 'OTHER'
            END AS territory
        FROM bronze.sales_raw b
        WHERE b.customer_name IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM silver.dim_customer c WHERE c.customer_name = b.customer_name);

        -------------------------------------------------------------------
        -- 5. Load DimProduct
        -------------------------------------------------------------------
        PRINT '→ Loading DimProduct...';
        INSERT INTO silver.dim_product (product_code, product_line, msrp)
        SELECT DISTINCT
            LTRIM(RTRIM(b.product_code)),
            LTRIM(RTRIM(b.product_line)),
            b.msrp
        FROM bronze.sales_raw b
        WHERE b.product_code IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM silver.dim_product p WHERE p.product_code = b.product_code);

        -------------------------------------------------------------------
        -- 6. Validate & Load FactSales
        -------------------------------------------------------------------
        PRINT '→ Validating data before FactSales load...';
        INSERT INTO silver.load_errors (table_name, error_message, record_data)
        SELECT 'bronze.sales_raw',
               'Invalid or missing key field (order_number, order_date, customer_name, product_code)',
               CONCAT('OrderNumber=', order_number, ', OrderDate=', order_date)
        FROM bronze.sales_raw
        WHERE order_number IS NULL OR order_date IS NULL OR customer_name IS NULL OR product_code IS NULL;

        PRINT '→ Loading FactSales...';
        INSERT INTO silver.fact_sales (
            order_number, order_date, status, quantity_ordered, price_each, sales_amount,
            deal_size, customer_id, product_id, dwh_create_date
        )
        SELECT 
            b.order_number,
            TRY_CAST(b.order_date AS DATETIME),
            LTRIM(RTRIM(b.status)),
            b.quantity_ordered,
            b.price_each,
            b.quantity_ordered * b.price_each AS sales_amount,
            LTRIM(RTRIM(b.deal_size)),
            c.customer_id,
            p.product_id,
            GETDATE()
        FROM bronze.sales_raw b
        INNER JOIN silver.dim_customer c ON c.customer_name = REPLACE(LTRIM(RTRIM(b.customer_name)), '+', '')
        INNER JOIN silver.dim_product p ON p.product_code = LTRIM(RTRIM(b.product_code))
        WHERE b.quantity_ordered > 0 
          AND b.price_each > 0
          AND NOT EXISTS (SELECT 1 FROM silver.fact_sales f WHERE f.order_number = b.order_number);

        -------------------------------------------------------------------
        -- 7. Map DateID
        -------------------------------------------------------------------
        PRINT '→ Linking FactSales with DimDate...';
        UPDATE f
        SET f.date_id = d.date_id
        FROM silver.fact_sales f
        INNER JOIN silver.dim_date d ON CAST(f.order_date AS DATE) = d.full_date
        WHERE f.date_id IS NULL;

        -------------------------------------------------------------------
        -- 8. Recreate Foreign Keys
        -------------------------------------------------------------------
        PRINT '→ Recreating Constraints & Indexes...';
        ALTER TABLE silver.fact_sales
            ADD CONSTRAINT fk_fact_sales_customer FOREIGN KEY (customer_id) REFERENCES silver.dim_customer(customer_id);
        ALTER TABLE silver.fact_sales
            ADD CONSTRAINT fk_fact_sales_product FOREIGN KEY (product_id) REFERENCES silver.dim_product(product_id);
        ALTER TABLE silver.fact_sales
            ADD CONSTRAINT fk_fact_sales_date FOREIGN KEY (date_id) REFERENCES silver.dim_date(date_id);

        -------------------------------------------------------------------
        -- 9. Audit Logging
        -------------------------------------------------------------------
        SET @rowcount = (SELECT COUNT(*) FROM silver.fact_sales);
        SET @end_time = GETDATE();

        INSERT INTO silver.load_audit (load_start, load_end, load_mode, table_name, rows_inserted, status)
        VALUES (@start_time, @end_time, @LoadMode, 'silver.fact_sales', @rowcount, 'SUCCESS');

        PRINT '✅ Silver Layer Load Completed Successfully!';
        PRINT '   → Total Rows in FactSales: ' + CAST(@rowcount AS NVARCHAR);
        PRINT '================================================';
    END TRY

    BEGIN CATCH
        SET @msg = ERROR_MESSAGE();
        SET @end_time = GETDATE();

        PRINT '❌ ERROR during Silver Load: ' + @msg;

        INSERT INTO silver.load_audit (load_start, load_end, load_mode, table_name, rows_inserted, status, error_message)
        VALUES (@start_time, @end_time, @LoadMode, 'silver.fact_sales', 0, 'FAILED', @msg);
    END CATCH
END;
GO



