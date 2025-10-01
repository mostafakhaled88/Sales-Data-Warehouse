/*
=============================================================
Bronze Layer DDL - Raw Ingestion
=============================================================
Database: SalesDWH
Purpose:
    - Create a single raw table in the Bronze schema.
    - Store all source data as-is (no transformations).
    - Silver layer will later create Fact & Dimension tables.
=============================================================
*/

USE SalesDWH;
GO

-- Drop existing raw table if needed
IF OBJECT_ID('bronze.sales_raw', 'U') IS NOT NULL
    DROP TABLE bronze.sales_raw;
GO

-- Create Bronze Raw Table
CREATE TABLE bronze.sales_raw
(
    -- Customer Info
    CustomerId       INT,
    FirstName        NVARCHAR(100),
    LastName         NVARCHAR(100),
    City             NVARCHAR(100),
    Country          NVARCHAR(100),
    Phone            NVARCHAR(50),

    -- Order Info
    OrderId          INT,
    OrderDate        DATETIME,
    OrderNumber      NVARCHAR(50),
    TotalAmount      DECIMAL(18,2),

    -- Order Item Info
    OrderItemId      INT,
    ProductId        INT,
    Order_UnitPrice  DECIMAL(18,2),
    Quantity         INT,

    -- Product Info
    ProductName      NVARCHAR(200),
    SupplierId       INT,
    Product_UnitPrice DECIMAL(18,2),
    Package          NVARCHAR(100),
    IsDiscontinued   BIT,

    -- Supplier Info
    SupplierName     NVARCHAR(200)
);
GO

PRINT ' Bronze layer table [bronze.sales_raw] created successfully.';
