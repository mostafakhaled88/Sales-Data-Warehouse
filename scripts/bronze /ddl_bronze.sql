/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/
USE SalesDWH;
GO

-- Drop existing raw table if needed
IF OBJECT_ID('bronze.sales_raw', 'U') IS NOT NULL
    DROP TABLE bronze.sales_raw;
GO

-- Create Bronze Raw Table (all as NVARCHAR)
CREATE TABLE bronze.sales_raw
(
    -- Customer Info
    CustomerId          NVARCHAR(50) NULL,
    FirstName           NVARCHAR(100) NULL,
    LastName            NVARCHAR(100) NULL,
    City                NVARCHAR(100) NULL,
    Country             NVARCHAR(100) NULL,
    Phone               NVARCHAR(50) NULL,

    -- Order Info
    OrderId             NVARCHAR(50) NULL,
    OrderDate           NVARCHAR(50) NULL,
    OrderNumber         NVARCHAR(50) NULL,
    TotalAmount         NVARCHAR(50) NULL,

    -- Order Item Info
    OrderItemId         NVARCHAR(50) NULL,
    ProductId           NVARCHAR(50) NULL,
    Order_UnitPrice     NVARCHAR(50) NULL,
    Quantity            NVARCHAR(50) NULL,

    -- Product Info
    ProductName         NVARCHAR(200) NULL,
    SupplierId          NVARCHAR(50) NULL,
    Product_UnitPrice   NVARCHAR(50) NULL,
    Package             NVARCHAR(100) NULL,
    IsDiscontinued      NVARCHAR(50) NULL,

    -- Supplier Info
    SupplierName        NVARCHAR(200) NULL
);
GO

PRINT 'Bronze layer table [bronze.sales_raw] created successfully.';
