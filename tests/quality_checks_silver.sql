USE SalesDWH;
GO

IF OBJECT_ID('silver.QualityReport', 'U') IS NOT NULL
    DROP TABLE silver.QualityReport;
GO

CREATE TABLE silver.QualityReport (
    ReportID INT IDENTITY(1,1) PRIMARY KEY,
    TestName NVARCHAR(200),
    Status NVARCHAR(20),
    IssueCount INT NULL,
    Details NVARCHAR(500) NULL,
    RunDate DATETIME DEFAULT GETDATE()
    ADD RunID INT
);


CREATE OR ALTER PROCEDURE silver.run_data_quality_tests
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '==============================================================';
    PRINT '🧪 STARTING SILVER LAYER DATA QUALITY VALIDATION';
    PRINT '==============================================================';

    IF OBJECT_ID('silver.QualityReport', 'U') IS NULL
    BEGIN
        CREATE TABLE silver.QualityReport (
            ReportID INT IDENTITY(1,1) PRIMARY KEY,
            TestName NVARCHAR(200),
            Status NVARCHAR(20),
            IssueCount INT NULL,
            Details NVARCHAR(500) NULL,
            RunDate DATETIME DEFAULT GETDATE()
        );
    END

    TRUNCATE TABLE silver.QualityReport;

    DECLARE @Issues INT, @BronzeCount INT, @SilverCount INT, @DupCount INT;
    DECLARE @BronzeSales MONEY, @SilverSales MONEY;

    ----------------------------------------------------------
    -- 1️⃣ Row Count Validation
    ----------------------------------------------------------
    SELECT @BronzeCount = COUNT(*) FROM bronze.sales_raw;
    SELECT @SilverCount = COUNT(*) FROM silver.fact_sales;

    INSERT INTO silver.QualityReport (TestName, Status, Details)
    VALUES (
        'FactSales Row Count',
        CASE WHEN @BronzeCount = @SilverCount THEN 'Passed' ELSE 'Failed' END,
        CONCAT('Bronze=', @BronzeCount, ', Silver=', @SilverCount)
    );

    ----------------------------------------------------------
    -- 2️⃣ Primary Key Uniqueness
    ----------------------------------------------------------
    SELECT @DupCount = COUNT(*) - COUNT(DISTINCT customer_id) FROM silver.dim_customer;
    INSERT INTO silver.QualityReport (TestName, Status, IssueCount)
    VALUES ('DimCustomer PK Uniqueness', CASE WHEN @DupCount = 0 THEN 'Passed' ELSE 'Failed' END, @DupCount);

    SELECT @DupCount = COUNT(*) - COUNT(DISTINCT product_id) FROM silver.dim_product;
    INSERT INTO silver.QualityReport (TestName, Status, IssueCount)
    VALUES ('DimProduct PK Uniqueness', CASE WHEN @DupCount = 0 THEN 'Passed' ELSE 'Failed' END, @DupCount);

    SELECT @DupCount = COUNT(*) - COUNT(DISTINCT date_id) FROM silver.dim_date;
    INSERT INTO silver.QualityReport (TestName, Status, IssueCount)
    VALUES ('DimDate PK Uniqueness', CASE WHEN @DupCount = 0 THEN 'Passed' ELSE 'Failed' END, @DupCount);

    ----------------------------------------------------------
    -- 3️⃣ Foreign Key Integrity
    ----------------------------------------------------------
    SELECT @Issues = COUNT(*) FROM silver.fact_sales fs
    LEFT JOIN silver.dim_customer dc ON fs.customer_id = dc.customer_id
    WHERE dc.customer_id IS NULL;
    INSERT INTO silver.QualityReport (TestName, Status, IssueCount)
    VALUES ('FactSales → DimCustomer FK', CASE WHEN @Issues = 0 THEN 'Passed' ELSE 'Failed' END, @Issues);

    SELECT @Issues = COUNT(*) FROM silver.fact_sales fs
    LEFT JOIN silver.dim_product dp ON fs.product_id = dp.product_id
    WHERE dp.product_id IS NULL;
    INSERT INTO silver.QualityReport (TestName, Status, IssueCount)
    VALUES ('FactSales → DimProduct FK', CASE WHEN @Issues = 0 THEN 'Passed' ELSE 'Failed' END, @Issues);

    SELECT @Issues = COUNT(*) FROM silver.fact_sales fs
    LEFT JOIN silver.dim_date dd ON fs.date_id = dd.date_id
    WHERE dd.date_id IS NULL;
    INSERT INTO silver.QualityReport (TestName, Status, IssueCount)
    VALUES ('FactSales → DimDate FK', CASE WHEN @Issues = 0 THEN 'Passed' ELSE 'Failed' END, @Issues);

    ----------------------------------------------------------
    -- 4️⃣ Business Rule Check (sales_amount = qty × price)
    ----------------------------------------------------------
    SELECT @Issues = COUNT(*)
    FROM silver.fact_sales
    WHERE ABS(sales_amount - (quantity_ordered * price_each)) > 0.01;

    INSERT INTO silver.QualityReport (TestName, Status, IssueCount, Details)
    VALUES ('SalesAmount = Qty × Price',
            CASE WHEN @Issues = 0 THEN 'Passed' ELSE 'Failed' END,
            @Issues,
            CASE WHEN @Issues > 0 THEN 'Mismatched rows in FactSales' ELSE NULL END);

    ----------------------------------------------------------
    -- 5️⃣ Total Sales Comparison
    ----------------------------------------------------------
    SELECT @BronzeSales = SUM(Sales) FROM bronze.sales_raw;
    SELECT @SilverSales = SUM(sales_amount) FROM silver.fact_sales;

    INSERT INTO silver.QualityReport (TestName, Status, Details)
    VALUES ('Total Sales Bronze vs Silver',
            CASE WHEN ABS(@BronzeSales - @SilverSales) < 0.01 THEN 'Passed' ELSE 'Failed' END,
            CONCAT('Bronze=', @BronzeSales, ', Silver=', @SilverSales));

    ----------------------------------------------------------
    -- 📋 Final Output
    ----------------------------------------------------------
    PRINT '==============================================================';
    PRINT '✅ DATA QUALITY VALIDATION COMPLETED';
    PRINT '==============================================================';

    SELECT * FROM silver.QualityReport ORDER BY ReportID;

END;
GO
