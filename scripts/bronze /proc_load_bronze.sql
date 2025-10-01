/*
=============================================================
Procedure: bronze.proc_load_bronze
=============================================================
Purpose:
    - Load raw CSV data into Bronze layer using BULK INSERT.
    - Path: C:\SQLData\sales_data.csv
    - This procedure truncates the raw table before loading.
=============================================================
*/

USE SalesDWH;
GO

IF OBJECT_ID('bronze.proc_load_bronze', 'P') IS NOT NULL
    DROP PROCEDURE bronze.proc_load_bronze;
GO

CREATE PROCEDURE bronze.proc_load_bronze
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '🔄 Starting Bronze Load...';

    -- Truncate existing data
    TRUNCATE TABLE bronze.sales_raw;

    -- Bulk insert from CSV
    BULK INSERT bronze.sales_raw
    FROM 'C:\SQLData\sales_data.csv'
    WITH 
    (
        FIRSTROW = 2,                 -- Skip header row
        FIELDTERMINATOR = ',',        -- Column delimiter
        ROWTERMINATOR = '0x0a',       -- Line feed (\n)
        TABLOCK,
        CODEPAGE = '65001'            -- UTF-8 support
    );

    PRINT '✅ Bronze Load Completed Successfully.';
END;
GO
