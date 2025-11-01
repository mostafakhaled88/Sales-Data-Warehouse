/*===============================================================================
    Script:     Create Bronze Tables
    Schema:     bronze
    Database:   SalesDWH
    Purpose:    Define raw ingestion table(s) for the Bronze Layer
    Author:     Mostafa Khaled Farag
    Date:       2025-11-01
    Version:    Production Ready
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
    load_dtm             DATETIME DEFAULT GETDATE() -- Audit column
);
GO

-------------------------------------------------------------------------------
-- 4. Confirmation Message
-------------------------------------------------------------------------------
PRINT ' Bronze table [bronze.sales_raw] created successfully.';
GO
