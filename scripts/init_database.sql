/*=============================================================
    Script:    Create Database and Schemas for SalesDWH
    Purpose:   Initialize Medallion Architecture (Bronze, Silver, Gold)
    Author:    Mostafa Khaled Farag
    Version:   Production Ready
    Date:      2025-11-01

    Description:
        - Drops existing SalesDWH database (if any)
        - Recreates it fresh
        - Creates bronze, silver, and gold schemas
        - Creates audit and error tracking tables

    WARNING:
        Running this script will DROP the existing SalesDWH database.
        All previous data will be permanently deleted.
        Ensure you have valid backups before execution.
==============================================================*/

USE master;
GO

---------------------------------------------------------------
-- Drop existing database (if any)
---------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'SalesDWH')
BEGIN
    PRINT 'Existing SalesDWH database found. Dropping...';
    ALTER DATABASE SalesDWH SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SalesDWH;
    PRINT 'Old SalesDWH database dropped.';
END;
GO

---------------------------------------------------------------
-- Create new database
---------------------------------------------------------------
CREATE DATABASE SalesDWH;
GO

USE SalesDWH;
GO

---------------------------------------------------------------
-- Create Schemas (Medallion Architecture)
---------------------------------------------------------------
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO

PRINT 'Schemas [bronze], [silver], and [gold] successfully created.';
GO

---------------------------------------------------------------
-- Create Audit & Error Tables
---------------------------------------------------------------
IF OBJECT_ID('dbo.load_audit') IS NULL
BEGIN
    CREATE TABLE dbo.load_audit (
        audit_id INT IDENTITY(1,1) PRIMARY KEY,
        load_start DATETIME DEFAULT GETDATE(),
        load_end DATETIME NULL,
        load_mode NVARCHAR(20),
        table_name NVARCHAR(100),
        rows_inserted INT,
        status NVARCHAR(20),
        error_message NVARCHAR(4000)
    );
    PRINT 'Table [dbo.load_audit] created.';
END;
GO

IF OBJECT_ID('dbo.load_errors') IS NULL
BEGIN
    CREATE TABLE dbo.load_errors (
        error_id INT IDENTITY(1,1) PRIMARY KEY,
        table_name NVARCHAR(100),
        error_message NVARCHAR(4000),
        record_data NVARCHAR(MAX),
        error_time DATETIME DEFAULT GETDATE()
    );
    PRINT 'Table [dbo.load_errors] created.';
END;
GO

---------------------------------------------------------------
-- Final Confirmation
---------------------------------------------------------------
PRINT ' SalesDWH initialized successfully with bronze, silver, gold schemas and audit tables.';
GO
