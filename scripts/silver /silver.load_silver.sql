/*
===============================================================================
Stored Procedure: silver.load_silver
===============================================================================
Purpose:
    Load data from the Bronze layer (raw data) into the Silver layer (cleaned, 
    structured, and conformed tables). The process includes:
    - Truncating existing Silver tables.
    - Cleaning and transforming data.
    - Populating DimCustomer, DimProduct, and FactSales tables.

Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/

USE SalesDWH;
GO

IF OBJECT_ID('silver.load_silver', 'P') IS NOT NULL
    DROP PROCEDURE silver.load_silver;
GO

CREATE PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start_time DATETIME = GETDATE();
    PRINT '================================================';
    PRINT '⚙️  Starting Silver Layer Load';
    PRINT '================================================';

    BEGIN TRY
        -------------------------------------------------------------------
        -- 1. Drop Foreign Key Constraints
        -------------------------------------------------------------------
        PRINT '→ Dropping Foreign Key Constraints...';
        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_fact_sales_customer')
            ALTER TABLE silver.fact_sales DROP CONSTRAINT fk_fact_sales_customer;

        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_fact_sales_product')
            ALTER TABLE silver.fact_sales DROP CONSTRAINT fk_fact_sales_product;

        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_fact_sales_date')
            ALTER TABLE silver.fact_sales DROP CONSTRAINT fk_fact_sales_date;

        -------------------------------------------------------------------
        -- 2. Truncate Tables
        -------------------------------------------------------------------
        PRINT '→ Truncating Silver Tables...';
        TRUNCATE TABLE silver.fact_sales;
        TRUNCATE TABLE silver.dim_customer;
        TRUNCATE TABLE silver.dim_product;
        TRUNCATE TABLE silver.dim_date;

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
        INSERT INTO silver.dim_date
        (
            full_date,
            day_number,
            month_number,
            month_name,
            quarter_name,
            year_number,
            dwh_create_date
        )
        SELECT 
            full_date,
            DAY(full_date),
            MONTH(full_date),
            DATENAME(MONTH, full_date),
            'Q' + CAST(DATEPART(QUARTER, full_date) AS NVARCHAR),
            YEAR(full_date),
            GETDATE()
        FROM AllDates
        OPTION (MAXRECURSION 0);

        PRINT '✅ DimDate Load Completed.';

        -------------------------------------------------------------------
        -- 4. Load DimCustomer
        -------------------------------------------------------------------
        PRINT '→ Loading DimCustomer...';
        INSERT INTO silver.dim_customer
        (
            customer_name,
            contact_first_name,
            contact_last_name,
            phone,
            address_line,
            city,
            state,
            postal_code,
            country,
            territory
        )
        SELECT DISTINCT
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(b.customer_name)), '+', ''), '(', ''), ')', ''), '"', ''), '.', ''), ',', ''), '/', '') AS customer_name,
            REPLACE(LTRIM(RTRIM(b.contact_first_name)), '-', '') AS contact_first_name,
            REPLACE(LTRIM(RTRIM(b.contact_last_name)), '-', '') AS contact_last_name,
            dbo.KeepDigits(b.PHONE) AS phone,  
            LTRIM(RTRIM(
                CASE 
                    WHEN RIGHT(LTRIM(RTRIM(b.address_line1)), 1) IN ('.', ',') 
                    THEN LEFT(LTRIM(RTRIM(b.address_line1)), LEN(LTRIM(RTRIM(b.address_line1))) - 1)
                    ELSE LTRIM(RTRIM(b.address_line1))
                END
            )) AS address_line,
            LTRIM(RTRIM(
                CASE 
                    WHEN RIGHT(LTRIM(RTRIM(b.CITY)), 1) IN ('.', ',') 
                    THEN LEFT(LTRIM(RTRIM(b.CITY)), LEN(LTRIM(RTRIM(b.CITY))) - 1)
                    ELSE LTRIM(RTRIM(b.CITY))
                END
            )) AS city,
            CASE 
                WHEN b.STATE IS NULL THEN 'UNKNOWN'
                ELSE UPPER(LTRIM(RTRIM(
                    CASE 
                        WHEN RIGHT(LTRIM(RTRIM(b.STATE)), 1) IN ('.', ',') 
                        THEN LEFT(LTRIM(RTRIM(b.STATE)), LEN(LTRIM(RTRIM(b.STATE))) - 1)
                        ELSE LTRIM(RTRIM(b.STATE))
                    END
                )))
            END AS state,
            CASE 
                WHEN b.postal_code IS NULL THEN 'Unknown'
                ELSE UPPER(LTRIM(RTRIM(b.postal_code)))
            END AS postal_code,
            LTRIM(RTRIM(b.COUNTRY)) AS country,
            CASE 
                WHEN UPPER(LTRIM(RTRIM(b.COUNTRY))) IN ('USA','CANADA','MEXICO') THEN 'NA'
                WHEN UPPER(LTRIM(RTRIM(b.COUNTRY))) IN ('FRANCE','GERMANY','ITALY','SPAIN','UK','BELGIUM','NORWAY','SWEDEN','AUSTRIA','SWITZERLAND','IRELAND','DENMARK','FINLAND') THEN 'EMEA'
                WHEN UPPER(LTRIM(RTRIM(b.COUNTRY))) IN ('AUSTRALIA','SINGAPORE','JAPAN','PHILIPPINES') THEN 'APAC'
                ELSE 'OTHER'
            END AS territory
        FROM bronze.sales_raw AS b
        WHERE b.customer_name IS NOT NULL;

        PRINT '✅ DimCustomer Load Completed.';

        -------------------------------------------------------------------
        -- 5. Load DimProduct
        -------------------------------------------------------------------
        PRINT '→ Loading DimProduct...';
        INSERT INTO silver.dim_product
        (
            product_code,
            product_line,
            msrp
        )
        SELECT DISTINCT
            LTRIM(RTRIM(b.product_code)),
            LTRIM(RTRIM(b.product_line)),
            b.MSRP
        FROM bronze.sales_raw AS b
        WHERE b.product_code IS NOT NULL;

        PRINT '✅ DimProduct Load Completed.';

        -------------------------------------------------------------------
        -- 6. Load FactSales
        -------------------------------------------------------------------
        PRINT '→ Loading FactSales...';
        INSERT INTO silver.fact_sales
        (
            order_number,
            order_date,
            status,
            quantity_ordered,
            price_each,
            sales_amount,
            deal_size,
            customer_id,
            product_id,
            dwh_create_date
        )
        SELECT 
            b.order_number,
            TRY_CAST(b.order_date AS DATETIME),
            LTRIM(RTRIM(b.STATUS)),
            b.quantity_ordered,
            b.price_each,
             b.quantity_ordered *b.price_each AS sales_amount ,
            LTRIM(RTRIM(b.deal_size)),
            c.customer_id,
            p.product_id,
            GETDATE()
        FROM bronze.sales_raw AS b
        LEFT JOIN silver.dim_customer AS c
            ON REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(b.customer_name)), '+', ''), '(', ''), ')', ''), '"', ''), '.', ''), ',', ''), '/', '') = c.customer_name
        LEFT JOIN silver.dim_product AS p
            ON LTRIM(RTRIM(b.product_code)) = p.product_code;

        PRINT '✅ FactSales Load Completed.';

        -------------------------------------------------------------------
        -- 7. Map DateID in FactSales
        -------------------------------------------------------------------
        PRINT '→ Linking FactSales with DimDate...';
        UPDATE f
        SET f.date_id = d.date_id
        FROM silver.fact_sales AS f
        INNER JOIN silver.dim_date AS d
            ON CAST(f.order_date AS DATE) = d.full_date;

        IF EXISTS (SELECT 1 FROM silver.fact_sales WHERE date_id IS NULL)
            THROW 50000, 'Some FactSales rows still have NULL date_id!', 1;

        PRINT '✅ DateID Mapping Completed.';

        -------------------------------------------------------------------
        -- 8. Recreate Foreign Key Constraints
        -------------------------------------------------------------------
        PRINT '→ Recreating Foreign Key Constraints...';
        ALTER TABLE silver.fact_sales
            ADD CONSTRAINT fk_fact_sales_customer FOREIGN KEY (customer_id)
            REFERENCES silver.dim_customer(customer_id);

        ALTER TABLE silver.fact_sales
            ADD CONSTRAINT fk_fact_sales_product FOREIGN KEY (product_id)
            REFERENCES silver.dim_product(product_id);

        ALTER TABLE silver.fact_sales
            ADD CONSTRAINT fk_fact_sales_date FOREIGN KEY (date_id)
            REFERENCES silver.dim_date(date_id);

        -------------------------------------------------------------------
        -- 9. Summary
        -------------------------------------------------------------------
        DECLARE @end_time DATETIME = GETDATE();
        PRINT '================================================';
        PRINT '✅ Silver Layer Load Completed Successfully!';
        PRINT '   - Total Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '================================================';
    END TRY

    BEGIN CATCH
        PRINT '================================================';
        PRINT '❌ ERROR OCCURRED DURING SILVER LOAD';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '================================================';
    END CATCH
END;
GO
