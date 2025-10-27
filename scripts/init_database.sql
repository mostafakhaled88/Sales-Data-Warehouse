/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'SalesDWH' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.
	
WARNING:
    Running this script will drop the entire 'SalesDWH' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/


USE master;
GO

-- Drop and recreate the 'SalesDWH' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'SalesDWH')
BEGIN
    ALTER DATABASE SalesDWH SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SalesDWH;
END;
GO

-- Create the 'DataWarehouse' database
CREATE DATABASE SalesDWH;
GO

-- Switch to new database
USE SalesDWH;
GO

-- Create Schemas for Medallion Architecture
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO

PRINT ' DataWarehouse initialized with bronze, silver, and gold schemas.';

        --  Ensure Audit & Error Tables Exist
        
        IF OBJECT_ID('load_audit') IS NULL
        CREATE TABLE load_audit (
            audit_id INT IDENTITY(1,1) PRIMARY KEY,
            load_start DATETIME,
            load_end DATETIME,
            load_mode NVARCHAR(20),
            table_name NVARCHAR(100),
            rows_inserted INT,
            status NVARCHAR(20),
            error_message NVARCHAR(4000)
  
        );

        IF OBJECT_ID('load_errors') IS NULL
        CREATE TABLE load_errors (
            error_id INT IDENTITY(1,1) PRIMARY KEY,
            table_name NVARCHAR(100),
            error_message NVARCHAR(4000),
            record_data NVARCHAR(MAX),
            error_time DATETIME DEFAULT GETDATE()
        );

PRINT ' load_audit and load_errors created';

