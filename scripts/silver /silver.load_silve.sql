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
        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_FactSales_DimCustomer')
            ALTER TABLE silver.FactSales DROP CONSTRAINT FK_FactSales_DimCustomer;

        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_FactSales_DimProduct')
            ALTER TABLE silver.FactSales DROP CONSTRAINT FK_FactSales_DimProduct;

        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_FactSales_DimDate')
            ALTER TABLE silver.FactSales DROP CONSTRAINT FK_FactSales_DimDate;

        -------------------------------------------------------------------
        -- 2. Truncate Tables
        -------------------------------------------------------------------
        PRINT '→ Truncating Silver Tables...';
        TRUNCATE TABLE silver.FactSales;
        TRUNCATE TABLE silver.DimCustomer;
        TRUNCATE TABLE silver.DimProduct;
        TRUNCATE TABLE silver.DimDate;

        -------------------------------------------------------------------
        -- 3. Load DimDate
        -------------------------------------------------------------------
        PRINT '→ Loading DimDate...';

        DECLARE @MinDate DATE, @MaxDate DATE;

        SELECT 
            @MinDate = MIN(TRY_CAST(OrderDate AS DATE)),
            @MaxDate = MAX(TRY_CAST(OrderDate AS DATE))
        FROM bronze.sales_raw;

        ;WITH AllDates AS (
            SELECT @MinDate AS FullDate
            UNION ALL
            SELECT DATEADD(DAY, 1, FullDate)
            FROM AllDates
            WHERE FullDate < @MaxDate
        )
        INSERT INTO silver.DimDate
        (
            FullDate,
            [Day],
            Month_ID,
            MonthName,
            Qtr_ID,
            QuarterName,
            Year_ID,
            YearName,
            dwh_create_date
        )
        SELECT 
            FullDate,
            DAY(FullDate),
            MONTH(FullDate),
            DATENAME(MONTH, FullDate),
            DATEPART(QUARTER, FullDate),
            'Q' + CAST(DATEPART(QUARTER, FullDate) AS NVARCHAR),
            YEAR(FullDate),
            CAST(YEAR(FullDate) AS NVARCHAR),
            GETDATE()
        FROM AllDates
        OPTION (MAXRECURSION 0);

        PRINT '✅ DimDate Load Completed.';

        -------------------------------------------------------------------
        -- 4. Load DimCustomer
        -------------------------------------------------------------------
        PRINT '→ Loading DimCustomer...';
        INSERT INTO silver.DimCustomer
        (
            CustomerName,
            ContactFirstName,
            ContactLastName,
            Phone,
            AddressLine1,
            City,
            State,
            PostalCode,
            Country,
            Territory
        )
        SELECT DISTINCT
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( LTRIM(RTRIM(b.CUSTOMERNAME)), '+', ''), '(', ''), ')', ''), '"', ''), '.', ''), ',', ''), '/', '') AS CustomerName,
            REPLACE(LTRIM(RTRIM(b.CONTACTFIRSTNAME)),'-',''),
            REPLACE(LTRIM(RTRIM(b.CONTACTLASTNAME)),'-',''),
			dbo.KeepDigits(PHONE) AS Phone,  
           LTRIM(RTRIM(
                CASE 
                    WHEN RIGHT(LTRIM(RTRIM(ADDRESSLINE1)), 1) IN ('.', ',') 
                    THEN LEFT(LTRIM(RTRIM(ADDRESSLINE1)), LEN(LTRIM(RTRIM(ADDRESSLINE1))) - 1)
                    ELSE LTRIM(RTRIM(ADDRESSLINE1))
                END
            )) AS AddressLine1,
           LTRIM(RTRIM(
    CASE 
        WHEN RIGHT(LTRIM(RTRIM(CITY)), 1) IN ('.', ',') 
        THEN LEFT(LTRIM(RTRIM(CITY)), LEN(LTRIM(RTRIM(CITY))) - 1)
        ELSE LTRIM(RTRIM(CITY))
    END
)) AS City,
           -- Clean State
CASE 
    WHEN STATE IS NULL THEN 'UNKNOWN'
    ELSE UPPER(LTRIM(RTRIM(
        CASE 
            WHEN RIGHT(LTRIM(RTRIM(STATE)), 1) IN ('.', ',') 
            THEN LEFT(LTRIM(RTRIM(STATE)), LEN(LTRIM(RTRIM(STATE))) - 1)
            ELSE LTRIM(RTRIM(STATE))
        END
    )))
END AS State,

            CASE 
        WHEN b.POSTALCODE IS NULL THEN 'Unknown'
        ELSE UPPER(LTRIM(RTRIM(b.POSTALCODE)))
    END AS PostalCode,
            LTRIM(RTRIM(b.COUNTRY)),
           CASE 
    WHEN UPPER(LTRIM(RTRIM(b.COUNTRY))) IN ('USA','CANADA','MEXICO') THEN 'NA'
    WHEN UPPER(LTRIM(RTRIM(b.COUNTRY))) IN ('FRANCE','GERMANY','ITALY','SPAIN','UK','BELGIUM','NORWAY','SWEDEN','AUSTRIA','SWITZERLAND','IRELAND','DENMARK','FINLAND') THEN 'EMEA'
    WHEN UPPER(LTRIM(RTRIM(b.COUNTRY))) IN ('AUSTRALIA','SINGAPORE','JAPAN','PHILIPPINES') THEN 'APAC'
    ELSE 'OTHER'
END AS Territory
        FROM bronze.sales_raw AS b
        WHERE b.CUSTOMERNAME IS NOT NULL;

        PRINT '✅ DimCustomer Load Completed.';

        -------------------------------------------------------------------
        -- 5. Load DimProduct
        -------------------------------------------------------------------
        PRINT '→ Loading DimProduct...';
        INSERT INTO silver.DimProduct
        (
            ProductCode,
            ProductLine,
            MSRP
        )
        SELECT DISTINCT
            LTRIM(RTRIM(b.PRODUCTCODE)),
            LTRIM(RTRIM(b.PRODUCTLINE)),
            b.MSRP
        FROM bronze.sales_raw AS b
        WHERE b.PRODUCTCODE IS NOT NULL;

        PRINT '✅ DimProduct Load Completed.';

        -------------------------------------------------------------------
        -- 6. Load FactSales
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
            DealSize,
            Qtr_ID,
            Month_ID,
            Year_ID,
            CustomerID,
            ProductID,
            dwh_create_date
        )
        SELECT 
            b.ORDERNUMBER,
            TRY_CAST(b.ORDERDATE AS DATETIME),
            LTRIM(RTRIM(b.STATUS)),
            b.QUANTITYORDERED,
            b.PRICEEACH,
            b.SALES,
            LTRIM(RTRIM(b.DEALSIZE)),
            b.QTR_ID,
            b.MONTH_ID,
            b.YEAR_ID,
            c.CustomerID,
            p.ProductID,
            GETDATE()
        FROM bronze.sales_raw AS b
        LEFT JOIN silver.DimCustomer AS c
            ON  REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( LTRIM(RTRIM(b.CUSTOMERNAME)), '+', ''), '(', ''), ')', ''), '"', ''), '.', ''), ',', ''), '/', '')  = c.CustomerName
        LEFT JOIN silver.DimProduct AS p
            ON LTRIM(RTRIM(b.PRODUCTCODE)) = p.ProductCode;

        PRINT '✅ FactSales Load Completed.';

        -------------------------------------------------------------------
        -- 7. Map DateID in FactSales
        -------------------------------------------------------------------
        PRINT '→ Linking FactSales with DimDate...';
        UPDATE f
        SET f.DateID = d.DateID
        FROM silver.FactSales AS f
        INNER JOIN silver.DimDate AS d
            ON CAST(f.OrderDate AS DATE) = d.FullDate;

        -- Verify all DateIDs are populated
        IF EXISTS (SELECT 1 FROM silver.FactSales WHERE DateID IS NULL)
            THROW 50000, 'Some FactSales rows still have NULL DateID!', 1;

        PRINT '✅ DateID Mapping Completed.';

        -------------------------------------------------------------------
        -- 8. Recreate Foreign Key Constraints
        -------------------------------------------------------------------
        PRINT '→ Recreating Foreign Key Constraints...';
        ALTER TABLE silver.FactSales
            ADD CONSTRAINT FK_FactSales_DimCustomer FOREIGN KEY (CustomerID)
            REFERENCES silver.DimCustomer(CustomerID);

        ALTER TABLE silver.FactSales
            ADD CONSTRAINT FK_FactSales_DimProduct FOREIGN KEY (ProductID)
            REFERENCES silver.DimProduct(ProductID);

        ALTER TABLE silver.FactSales
            ADD CONSTRAINT FK_FactSales_DimDate FOREIGN KEY (DateID)
            REFERENCES silver.DimDate(DateID);

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

