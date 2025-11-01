/*===============================================================================
    Script:     Create Bronze Tables (Optimized for Incremental Loads)
    Schema:     bronze
    Database:   SalesDWH
    Purpose:    Define raw ingestion table(s) for the Bronze Layer
                 - Lightweight raw data store
                 - Supports incremental load detection via hash + audit columns
    Author:     Mostafa Khaled Farag
    Date:       2025-11-01
    Version:    v2 (Performance Optimized)
===============================================================================*/

USE SalesDWH;
GO

-------------------------------------------------------------------------------
-- 1. Ensure Schema Exists
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze')
BEGIN
    EXEC('CREATE SCHEMA bronze;');
    PRINT 'Schema [bronze] created.';
END;
ELSE
    PRINT 'Schema [bronze] already exists.';
GO

-------------------------------------------------------------------------------
-- 2. Drop Existing Table (if any)
-------------------------------------------------------------------------------
IF OBJECT_ID('bronze.sales_raw', 'U') IS NOT NULL
BEGIN
    DROP TABLE bronze.sales_raw;
    PRINT 'Dropped existing table [bronze.sales_raw].';
END;
GO

-------------------------------------------------------------------------------
-- 3. Create Table: bronze.sales_raw
-------------------------------------------------------------------------------
CREATE TABLE bronze.sales_raw (
    sales_raw_id         INT IDENTITY(1,1) PRIMARY KEY,  -- Surrogate key for tracking
    order_number         INT NULL,
    quantity_ordered     INT NULL,
    price_each           DECIMAL(10,2) NULL,
    order_line_number    INT NULL,
    order_date           VARCHAR(50) NULL,
    status               VARCHAR(50) NULL,
    qtr_id               INT NULL,
    month_id             INT NULL,
    year_id              INT NULL,
    product_line         VARCHAR(100) NULL,
    msrp                 INT NULL,
    product_code         VARCHAR(50) NULL,
    customer_name        VARCHAR(255) NULL,
    phone                VARCHAR(50) NULL,
    address_line1        VARCHAR(255) NULL,
    address_line2        VARCHAR(255) NULL,
    city                 VARCHAR(100) NULL,
    state                VARCHAR(100) NULL,
    postal_code          VARCHAR(20) NULL,
    country              VARCHAR(100) NULL,
    territory            VARCHAR(100) NULL,
    contact_last_name    VARCHAR(100) NULL,
    contact_first_name   VARCHAR(100) NULL,
    deal_size            VARCHAR(50) NULL,

    -- Audit Columns
    source_file_name     VARCHAR(255) NULL,   -- Useful for batch tracking
    load_dtm             DATETIME DEFAULT GETDATE(),
    row_hash             AS (CONVERT(VARCHAR(64), HASHBYTES('SHA2_256',
                          CONCAT(
                              ISNULL(CONVERT(VARCHAR(50), order_number), ''),
                              '|', ISNULL(product_code, ''),
                              '|', ISNULL(customer_name, ''),
                              '|', ISNULL(order_date, '')
                          )), 2)) PERSISTED   -- Helps detect new/changed rows
);
GO

-------------------------------------------------------------------------------
-- 4. Indexes for Incremental Load Performance
-------------------------------------------------------------------------------
-- Unique/lookup index for change detection (based on business keys)
CREATE UNIQUE INDEX IX_sales_raw_order_product_customer
    ON bronze.sales_raw(order_number, product_code, customer_name)
    WHERE order_number IS NOT NULL;

-- Hash index for faster incremental comparison
CREATE INDEX IX_sales_raw_hash
    ON bronze.sales_raw(row_hash);

-------------------------------------------------------------------------------
-- 5. Confirmation Message
-------------------------------------------------------------------------------
PRINT 'Bronze table [bronze.sales_raw] created successfully .';
GO
