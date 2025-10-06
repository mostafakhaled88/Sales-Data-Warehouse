/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
    Run this script to re-define the DDL structure of 'bronze' tables.
===============================================================================
*/

USE SalesDWH;
GO

-------------------------------------------------------------------------------
-- 1. Ensure Schema Exists
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
    EXEC('CREATE SCHEMA bronze');
GO

-------------------------------------------------------------------------------
-- 2. Drop Existing Table (if any)
-------------------------------------------------------------------------------
IF OBJECT_ID('bronze.sales_raw', 'U') IS NOT NULL
    DROP TABLE bronze.sales_raw;
GO

-------------------------------------------------------------------------------
-- 3. Create Table: bronze.sales_raw
-------------------------------------------------------------------------------
CREATE TABLE [SalesDWH].[bronze].[sales_raw] (
    order_number         INT,
    quantity_ordered     INT,
    price_each           DECIMAL(10,2),
    order_line_number    INT,
    sales                DECIMAL(12,2),
    order_date           VARCHAR(50),
    status               VARCHAR(50),
    qtr_id               INT,
    month_id             INT,
    year_id              INT,
    product_line         VARCHAR(100),
    msrp                 INT,
    product_code         VARCHAR(50),
    customer_name        VARCHAR(255),
    phone                VARCHAR(50),
    address_line1        VARCHAR(255),
    address_line2        VARCHAR(255),
    city                 VARCHAR(100),
    state                VARCHAR(100),
    postal_code          VARCHAR(20),
    country              VARCHAR(100),
    territory            VARCHAR(100),
    contact_last_name    VARCHAR(100),
    contact_first_name   VARCHAR(100),
    deal_size            VARCHAR(50)
);
GO

-------------------------------------------------------------------------------
-- 4. Confirmation Message
-------------------------------------------------------------------------------
PRINT 'Bronze table [bronze.sales_raw] created successfully.';
GO
