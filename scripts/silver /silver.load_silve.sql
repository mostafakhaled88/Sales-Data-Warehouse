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
        -- 1. Clear existing data
        -------------------------------------------------------------------
        PRINT '→ Truncating Silver Tables...';
        TRUNCATE TABLE silver.FactSales;
        TRUNCATE TABLE silver.DimCustomer;
        TRUNCATE TABLE silver.DimProduct;

        -------------------------------------------------------------------
        -- 2. Load DimCustomer
        -------------------------------------------------------------------
        PRINT '→ Loading DimCustomer...';
        INSERT INTO silver.DimCustomer
        (
            CustomerName,
            ContactFirstName,
            ContactLastName,
            Phone,
            AddressLine1,
            AddressLine2,
            City,
            State,
            PostalCode,
            Country,
            Territory,
            DealSize
        )
        SELECT DISTINCT
            LTRIM(RTRIM(CUSTOMERNAME)),
            LTRIM(RTRIM(CONTACTFIRSTNAME)),
            LTRIM(RTRIM(CONTACTLASTNAME)),
            LTRIM(RTRIM(PHONE)),
            LTRIM(RTRIM(ADDRESSLINE1)),
            LTRIM(RTRIM(ADDRESSLINE2)),
            LTRIM(RTRIM(CITY)),
            LTRIM(RTRIM(STATE)),
            LTRIM(RTRIM(POSTALCODE)),
            LTRIM(RTRIM(COUNTRY)),
            LTRIM(RTRIM(TERRITORY)),
            LTRIM(RTRIM(DEALSIZE))
        FROM bronze.sales_raw
        WHERE CUSTOMERNAME IS NOT NULL;

        PRINT '✅ DimCustomer Load Completed.';

        -------------------------------------------------------------------
        -- 3. Load DimProduct
        -------------------------------------------------------------------
        PRINT '→ Loading DimProduct...';
        INSERT INTO silver.DimProduct
        (
            ProductCode,
            ProductLine,
            MSRP
        )
        SELECT DISTINCT
            LTRIM(RTRIM(PRODUCTCODE)),
            LTRIM(RTRIM(PRODUCTLINE)),
            MSRP
        FROM bronze.sales_raw
        WHERE PRODUCTCODE IS NOT NULL;

        PRINT '✅ DimProduct Load Completed.';

        -------------------------------------------------------------------
        -- 4. Load FactSales
        -------------------------------------------------------------------
        PRINT '→ Loading FactSales...';
        INSERT INTO silver.FactSales
        (
            OrderNumber,
            OrderDate,
            Status,
            QuantityOrdered,
            PriceEach,
            Sales,
            Qtr_ID,
            Month_ID,
            Year_ID,
            ProductCode
        )
        SELECT 
            ORDERNUMBER,
            TRY_CAST(ORDERDATE AS DATETIME),
            LTRIM(RTRIM(STATUS)),
            QUANTITYORDERED,
            PRICEEACH,
            SALES,
            QTR_ID,
            MONTH_ID,
            YEAR_ID,
            PRODUCTCODE
        FROM bronze.sales_raw
        WHERE ORDERNUMBER IS NOT NULL;

        PRINT '✅ FactSales Load Completed.';

        -------------------------------------------------------------------
        -- 5. Summary
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
