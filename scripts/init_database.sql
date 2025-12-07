/*=============================================================
    Script:    01_Init_SalesDWH.sql
    Purpose:   Initialize Medallion Architecture (Bronze, Silver, Gold)
               + Metadata & Security Roles
               + Audit Logging
    Author:    Mostafa Khaled Farag
    Version:   2.2 (Database Drop/Create fix)
    Date:      2025-12-07

    WARNING:
        Running this script will DROP the existing SalesDWH database.
        Ensure valid backups before execution.
==============================================================*/

SET NOCOUNT ON;
-- Start in the master database to perform DB operations
USE master;
GO

---------------------------------------------------------------
-- Drop existing database (Must be its own GO batch)
---------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'SalesDWH')
BEGIN
    PRINT 'Existing SalesDWH detected. Dropping...';
    -- Force all connections to terminate so the DROP can proceed
    ALTER DATABASE SalesDWH SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SalesDWH;
    PRINT 'Old SalesDWH dropped successfully.';
END;
GO
---------------------------------------------------------------
-- Create new database (Must be its own GO batch)
---------------------------------------------------------------
CREATE DATABASE SalesDWH
ON (
    NAME = SalesDWH_data,
    FILENAME = 'C:\SQLData\SalesDWH.mdf'
)
LOG ON (
    NAME = SalesDWH_log,
    FILENAME = 'C:\SQLLogs\SalesDWH_log.ldf'
);
PRINT 'New SalesDWH database created.';
GO

-- Switch to the newly created database for subsequent object creation
USE SalesDWH;
GO

-- The rest of your script (Schema Creation, Audit Tables, Roles) follows here...
