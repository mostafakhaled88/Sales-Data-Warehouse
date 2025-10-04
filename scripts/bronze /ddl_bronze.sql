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
    ORDERNUMBER INT,
    QUANTITYORDERED INT,
    PRICEEACH DECIMAL(10,2),
    ORDERLINENUMBER INT,
    SALES DECIMAL(12,2),
    ORDERDATE DATETIME,
    STATUS NVARCHAR(50),
    QTR_ID INT,
    MONTH_ID INT,
    YEAR_ID INT,
    PRODUCTLINE NVARCHAR(100),
    MSRP DECIMAL(10,2),
    PRODUCTCODE NVARCHAR(50),
    CUSTOMERNAME NVARCHAR(255),
    PHONE NVARCHAR(50),
    ADDRESSLINE1 NVARCHAR(255),
    ADDRESSLINE2 NVARCHAR(255),
    CITY NVARCHAR(100),
    STATE NVARCHAR(100),
    POSTALCODE NVARCHAR(20),
    COUNTRY NVARCHAR(100),
    TERRITORY NVARCHAR(50),
    CONTACTLASTNAME NVARCHAR(100),
    CONTACTFIRSTNAME NVARCHAR(100),
    DEALSIZE NVARCHAR(50)
);
