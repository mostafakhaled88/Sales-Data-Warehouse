/*
=============================================================
Init Database and Schemas
=============================================================
Script Purpose:
    - Creates a new database named 'SalesDWH'
    - If it exists, drops and recreates it
    - Sets up three schemas: bronze, silver, and gold

WARNING:
    Running this script will DROP the existing 'DataWarehouse' 
    database and all its objects. 
    Make sure you have backups before executing.
=============================================================
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
