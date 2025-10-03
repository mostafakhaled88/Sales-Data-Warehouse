CREATE OR ALTER PROCEDURE sp_load_silver_fixed
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '⚡ Starting Silver Layer Reload...';

    -------------------------------------------------------------------
    -- Logging table (optional)
    -------------------------------------------------------------------
    -- Ensure this exists once in your DB
    -- CREATE TABLE SalesDWH.silver.LoadLog (TableName VARCHAR(50), RowCount INT, LoadDate DATETIME);

    -------------------------------------------------------------------
    -- 1. DimDate
    -------------------------------------------------------------------
    PRINT '→ Loading DimDate...';
    TRUNCATE TABLE SalesDWH.silver.DimDate;

    ;WITH DateRange AS (
        SELECT MIN(CAST(OrderDate AS date)) AS MinDate,
               MAX(CAST(OrderDate AS date)) AS MaxDate
        FROM SalesDWH.bronze.sales_raw
    ),
    AllDates AS (
        SELECT DATEADD(DAY, n, MinDate) AS FullDate
        FROM DateRange
        CROSS JOIN (
            SELECT TOP (10000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
            FROM sys.objects
        ) AS N
        WHERE DATEADD(DAY, n, MinDate) <= MaxDate
    )
    INSERT INTO SalesDWH.silver.DimDate
        (DateKey, FullDate, Year, Quarter, Month, DayOfMonth, DayName)
    SELECT 
        CAST(CONVERT(varchar(8), FullDate, 112) AS INT) AS DateKey,
        FullDate,
        YEAR(FullDate),
        DATEPART(QUARTER, FullDate),
        MONTH(FullDate),
        DAY(FullDate),
        DATENAME(WEEKDAY, FullDate)
    FROM AllDates;

    DECLARE @DimDateCount INT = @@ROWCOUNT;
    PRINT '✅ DimDate loaded: ' + CAST(@DimDateCount AS varchar);

    -------------------------------------------------------------------
    -- 2. DimLocation
    -------------------------------------------------------------------
    PRINT '→ Loading DimLocation...';
    DELETE FROM SalesDWH.silver.DimLocation;

    INSERT INTO SalesDWH.silver.DimLocation (City, PostalCode, Country, Territory)
    SELECT DISTINCT
        CASE
            WHEN CITY IS NULL OR LTRIM(RTRIM(CITY)) = '' OR CITY LIKE '%[0-9]%' 
                 OR CITY LIKE '%Floor%' OR CITY LIKE '%Level%' OR CITY LIKE '%PB%' 
                 OR CITY LIKE '%Apt%' OR CITY LIKE '%/' OR CITY LIKE 'rue du Commerce'
            THEN 'Unknown'
            WHEN CITY = 'NYC' THEN 'New York'
            ELSE LTRIM(RTRIM(REPLACE(CITY, '"', '')))
        END AS City,
        CASE
            WHEN Postalcode IS NULL OR LTRIM(RTRIM(Postalcode)) = '' THEN 'Unknown'
            WHEN PATINDEX('%[0-9]%', Postalcode) = 0 THEN 'Unknown'
            ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Postalcode,'+',''), '(',''),')',''),'"',''),'.',''),',',''),'/','')
        END AS PostalCode,
        CASE
            WHEN COUNTRY IS NULL OR LTRIM(RTRIM(COUNTRY)) = '' THEN 'Unknown'
            WHEN ISNUMERIC(COUNTRY) = 1 THEN 'Unknown'
            WHEN COUNTRY LIKE '%[0-9]%' THEN 'Unknown'
            WHEN COUNTRY IN ('Osaka','Tokyo','Sevilla','Paris','Lyon','Madrid') THEN 'Unknown'
            ELSE LTRIM(RTRIM(COUNTRY))
        END AS Country,
        CASE
            WHEN COUNTRY IN ('USA','Canada') THEN 'NA'
            WHEN COUNTRY IN ('France','Germany','UK','Spain','Belgium','Switzerland','Austria','Ireland','Norway',
                             'Sweden','Finland','Italy','Denmark') THEN 'EMEA'
            WHEN COUNTRY IN ('Japan','Australia','Singapore','Philippines','China','India') THEN 'APAC'
            ELSE 'Unknown'
        END AS Territory
    FROM SalesDWH.bronze.sales_raw;

    -- Ensure Unknown location exists
    IF NOT EXISTS (SELECT 1 FROM SalesDWH.silver.DimLocation WHERE City='Unknown' AND PostalCode='Unknown')
        INSERT INTO SalesDWH.silver.DimLocation (City, PostalCode, Country, Territory)
        VALUES ('Unknown','Unknown','Unknown','Unknown');

    DECLARE @DimLocationCount INT = @@ROWCOUNT;
    PRINT '✅ DimLocation loaded: ' + CAST(@DimLocationCount AS varchar);

    -------------------------------------------------------------------
    -- 3. DimCustomer
    -------------------------------------------------------------------
    PRINT '→ Loading DimCustomer...';
    TRUNCATE TABLE SalesDWH.silver.DimCustomer;

    INSERT INTO SalesDWH.silver.DimCustomer
        (CustomerName, Phone, AddressLine, ContactFirstName, LocationKey)
    SELECT DISTINCT
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([CUSTOMERNAME], '+', ''), '(', ''), ')', ''), '"', ''), '.', ''), ',', ''), '/', '') AS CustomerName,
        CASE 
            WHEN PATINDEX('%[0-9]%', REPLACE([PHONE], '+','')) = 0 THEN 'Unknown'
            ELSE REPLACE(REPLACE(REPLACE([PHONE], '+',''), '(',''),')','')
        END AS Phone,
        COALESCE(NULLIF(LTRIM(RTRIM(REPLACE([ADDRESSLINE1], '"',''))), ''), 
                 NULLIF(LTRIM(RTRIM(REPLACE([ADDRESSLINE2], '"',''))), '')) AS AddressLine,
        CASE 
            WHEN CONTACTFIRSTNAME IS NULL OR LTRIM(RTRIM(CONTACTFIRSTNAME)) = '' 
                 OR PATINDEX('%[0-9]%', CONTACTFIRSTNAME) > 0
            THEN 'Unknown'
            ELSE LTRIM(RTRIM(CONTACTFIRSTNAME))
        END AS ContactFirstName,
        ISNULL(l.LocationKey, (SELECT LocationKey FROM SalesDWH.silver.DimLocation WHERE City='Unknown' AND PostalCode='Unknown')) AS LocationKey
    FROM SalesDWH.bronze.sales_raw b
    LEFT JOIN SalesDWH.silver.DimLocation l
        ON ISNULL(NULLIF(LTRIM(RTRIM(b.City)), ''), 'Unknown') = l.City
       AND ISNULL(NULLIF(LTRIM(RTRIM(b.PostalCode)), ''), 'Unknown') = l.PostalCode
       AND ISNULL(NULLIF(LTRIM(RTRIM(b.Country)), ''), 'Unknown') = l.Country;

    DECLARE @DimCustomerCount INT = @@ROWCOUNT;
    PRINT '✅ DimCustomer loaded: ' + CAST(@DimCustomerCount AS varchar);

    -------------------------------------------------------------------
    -- 4. DimProduct
    -------------------------------------------------------------------
    PRINT '→ Loading DimProduct...';
    TRUNCATE TABLE SalesDWH.silver.DimProduct;

    INSERT INTO SalesDWH.silver.DimProduct (ProductCode, ProductLine, MSRP)
    SELECT DISTINCT
        ProductCode,
        ProductLine,
        TRY_CAST(NULLIF(REPLACE(REPLACE(REPLACE(MSRP, ',', ''), '$', ''), ' ', ''), '') AS DECIMAL(18,2)) AS MSRP
    FROM SalesDWH.bronze.sales_raw;

    DECLARE @DimProductCount INT = @@ROWCOUNT;
    PRINT '✅ DimProduct loaded: ' + CAST(@DimProductCount AS varchar);

    -------------------------------------------------------------------
    -- 5. DimOrder
    -------------------------------------------------------------------
    PRINT '→ Loading DimOrder...';
    TRUNCATE TABLE SalesDWH.silver.DimOrder;

    INSERT INTO SalesDWH.silver.DimOrder (OrderNumber, OrderDateKey, Status, CustomerKey, TotalAmount, LoadDate)
    SELECT 
        r.OrderNumber,
        d.DateKey,
        r.Status,
        c.CustomerKey,
        SUM(TRY_CAST(NULLIF(REPLACE(REPLACE(REPLACE(r.Sales, ',', ''), '$', ''), ' ', ''), '') AS DECIMAL(18,2))) AS TotalAmount,
        GETDATE() AS LoadDate
    FROM SalesDWH.bronze.sales_raw r
    JOIN SalesDWH.silver.DimDate d 
        ON CAST(r.OrderDate AS date) = d.FullDate
    JOIN SalesDWH.silver.DimCustomer c 
        ON REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(r.CustomerName, '+', ''), '(', ''), ')', ''), '"', ''), '.', ''), ',', ''), '/', '') = c.CustomerName
    GROUP BY r.OrderNumber, d.DateKey, r.Status, c.CustomerKey;

    DECLARE @DimOrderCount INT = @@ROWCOUNT;
    PRINT '✅ DimOrder loaded: ' + CAST(@DimOrderCount AS varchar);

    -------------------------------------------------------------------
    -- 6. FactSales
    -------------------------------------------------------------------
    PRINT '→ Loading FactSales...';
    TRUNCATE TABLE SalesDWH.silver.FactSales;

    INSERT INTO SalesDWH.silver.FactSales 
        (OrderKey, ProductKey, DateKey, QuantityOrdered, PriceEach, Sales, LoadDate)
    SELECT 
        o.OrderKey,
        p.ProductKey,
        d.DateKey,
        TRY_CAST(NULLIF(REPLACE(r.QuantityOrdered, ',', ''), '') AS INT),
        TRY_CAST(NULLIF(REPLACE(REPLACE(r.PriceEach, ',', ''), '$', ''), '') AS DECIMAL(18,2)),
        TRY_CAST(NULLIF(REPLACE(REPLACE(r.Sales, ',', ''), '$', ''), '') AS DECIMAL(18,2)),
        GETDATE()
    FROM SalesDWH.bronze.sales_raw r
    JOIN SalesDWH.silver.DimOrder o 
        ON r.OrderNumber = o.OrderNumber
    JOIN SalesDWH.silver.DimProduct p 
        ON r.ProductCode = p.ProductCode
    JOIN SalesDWH.silver.DimDate d 
        ON CAST(r.OrderDate AS date) = d.FullDate;

    DECLARE @FactSalesCount INT = @@ROWCOUNT;
    PRINT '✅ FactSales loaded: ' + CAST(@FactSalesCount AS varchar);

    

    -------------------------------------------------------------------
    PRINT '🎉 Silver Layer Reload Completed Successfully';
END
