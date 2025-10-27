/********************************************************************************************
  File: silver_ddl.sql
  Layer: Silver (Cleansed Data)
  Project: Sales Data Warehouse (SalesDWH)
  Description:
      Defines all tables for the Silver Layer:
      - DimDate
      - DimCustomer
      - DimProduct
      - FactSales
********************************************************************************************/

USE SalesDWH;
GO

/********************************************************************************************
  1. Drop Existing Tables (Order matters due to Foreign Keys)
********************************************************************************************/
IF OBJECT_ID('SalesDWH.silver.fact_sales', 'U') IS NOT NULL
    DROP TABLE SalesDWH.silver.fact_sales;
IF OBJECT_ID('SalesDWH.silver.dim_customer', 'U') IS NOT NULL
    DROP TABLE SalesDWH.silver.dim_customer;
IF OBJECT_ID('SalesDWH.silver.dim_product', 'U') IS NOT NULL
    DROP TABLE SalesDWH.silver.dim_product;
IF OBJECT_ID('SalesDWH.silver.dim_date', 'U') IS NOT NULL
    DROP TABLE SalesDWH.silver.dim_date;
GO


/********************************************************************************************
  2. Dimension: dim_date
********************************************************************************************/
CREATE TABLE SalesDWH.silver.dim_date
(
    date_id             INT IDENTITY(1,1) PRIMARY KEY,
    full_date           DATE NOT NULL,
    day_number          TINYINT,
    month_number        TINYINT,
    month_name          NVARCHAR(20),
    quarter_name        NVARCHAR(10),
    year_number         SMALLINT,
    dwh_create_date     DATETIME DEFAULT GETDATE()
);
GO


/********************************************************************************************
  3. Dimension: dim_customer
********************************************************************************************/
CREATE TABLE SalesDWH.silver.dim_customer
(
    customer_id         INT IDENTITY(1,1) PRIMARY KEY,
    customer_name       NVARCHAR(255),
    contact_first_name  NVARCHAR(100),
    contact_last_name   NVARCHAR(100),
    phone               NVARCHAR(50),
    address_line        NVARCHAR(255),
    city                NVARCHAR(100),
    state               NVARCHAR(100),
    postal_code         NVARCHAR(20),
    country             NVARCHAR(100),
    territory           NVARCHAR(50),
    dwh_create_date     DATETIME DEFAULT GETDATE()
);
GO


/********************************************************************************************
  4. Dimension: dim_product
********************************************************************************************/
CREATE TABLE SalesDWH.silver.dim_product
(
    product_id          INT IDENTITY(1,1) PRIMARY KEY,
    product_code        NVARCHAR(50),
    product_line        NVARCHAR(100),
    msrp                DECIMAL(10,2),
    dwh_create_date     DATETIME DEFAULT GETDATE()
);
GO


/********************************************************************************************
  5. Fact Table: fact_sales
********************************************************************************************/
CREATE TABLE SalesDWH.silver.fact_sales
(
    sales_id            INT IDENTITY(1,1) PRIMARY KEY,
    order_number        INT,
    order_date          DATETIME,
    status              NVARCHAR(50),
    quantity_ordered    INT,
    price_each          DECIMAL(10,2),
    sales_amount        DECIMAL(18,2),
    deal_size           NVARCHAR(20),

    -- Foreign Keys
    customer_id         INT,
    product_id          INT,
    date_id             INT,

    dwh_create_date     DATETIME DEFAULT GETDATE(),

    /*******************************************************
      Foreign Key Constraints
    *******************************************************/
    CONSTRAINT fk_fact_sales_customer
        FOREIGN KEY (customer_id)
        REFERENCES SalesDWH.silver.dim_customer(customer_id),

    CONSTRAINT fk_fact_sales_product
        FOREIGN KEY (product_id)
        REFERENCES SalesDWH.silver.dim_product(product_id),

    CONSTRAINT fk_fact_sales_date
        FOREIGN KEY (date_id)
        REFERENCES SalesDWH.silver.dim_date(date_id)
);
GO
  /********************************************************************************************
  End of Script
********************************************************************************************/
PRINT ' Silver layer DDL created successfully.';
GO
