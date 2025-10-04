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



CREATE TABLE [SalesDWH].[bronze].[sales_raw] (
    ORDERNUMBER INT,
    QUANTITYORDERED INT,
    PRICEEACH DECIMAL(10,2),
    ORDERLINENUMBER INT,
    SALES DECIMAL(12,2),
    ORDERDATE VARCHAR(50),
    STATUS VARCHAR(50),
    QTR_ID INT,
    MONTH_ID INT,
    YEAR_ID INT,
    PRODUCTLINE VARCHAR(100),
    MSRP INT,
    PRODUCTCODE VARCHAR(50),
    CUSTOMERNAME VARCHAR(255),
    PHONE VARCHAR(50),
    ADDRESSLINE1 VARCHAR(255),
    ADDRESSLINE2 VARCHAR(255),
    CITY VARCHAR(100),
    STATE VARCHAR(100),
    POSTALCODE VARCHAR(20),
    COUNTRY VARCHAR(100),
    TERRITORY VARCHAR(100),
    CONTACTLASTNAME VARCHAR(100),
    CONTACTFIRSTNAME VARCHAR(100),
    DEALSIZE VARCHAR(50)
);
