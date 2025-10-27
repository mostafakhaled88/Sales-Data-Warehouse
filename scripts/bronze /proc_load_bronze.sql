/*===============================================================================
  Stored Procedure: bronze.load_bronze
  ===============================================================================
  Purpose:
      Loads data from external CSV files into the Bronze Layer of the SalesDWH.
      This procedure:
        - Truncates existing data in the bronze table.
        - Loads new data using BULK INSERT from a specified CSV file.
        - Prints total rows loaded and load duration.

  Parameters:
      None.

  Usage Example:
     EXEC bronze.load_bronze @FilePath = 'C:\SQLData\sales_data.csv';
===============================================================================*/

USE SalesDWH;
GO

IF OBJECT_ID('bronze.load_bronze', 'P') IS NOT NULL
    DROP PROCEDURE bronze.load_bronze;
GO

CREATE PROCEDURE bronze.load_bronze
    @FilePath NVARCHAR(255) = 'C:\SQLData\sales_data.csv'  -- optional parameter
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @batch_start_time DATETIME = GETDATE(),
        @batch_end_time DATETIME,
        @rows_inserted INT = 0,
        @error_message NVARCHAR(MAX) = NULL,
        @load_status NVARCHAR(20) = 'SUCCESS';

    BEGIN TRY
        PRINT '============================================================';
        PRINT ' Starting Bronze Layer Load...';
        PRINT '============================================================';
        PRINT ' File Path: ' + @FilePath;

        -----------------------------------------------------------------------
        -- 1. Truncate Existing Data
        -----------------------------------------------------------------------
        PRINT ' Truncating existing data in [bronze].[sales_raw]...';
        TRUNCATE TABLE [bronze].[sales_raw];

        -----------------------------------------------------------------------
        -- 2. Bulk Insert Data from CSV File
        -----------------------------------------------------------------------
        PRINT ' Loading data from CSV file into [bronze].[sales_raw]...';

        DECLARE @sql NVARCHAR(MAX) = 
        N'BULK INSERT [SalesDWH].[bronze].[sales_raw]
          FROM ''' + @FilePath + N'''
          WITH (
              FORMAT = ''CSV'',
              FIRSTROW = 2,
              FIELDTERMINATOR = '','',
              ROWTERMINATOR = ''\n'',
              TABLOCK
          );';
        EXEC sp_executesql @sql;

        -----------------------------------------------------------------------
        -- 3. Count Rows
        -----------------------------------------------------------------------
        SELECT @rows_inserted = COUNT(*) FROM [bronze].[sales_raw];

        -----------------------------------------------------------------------
        -- 4. Completion Summary
        -----------------------------------------------------------------------
        SET @batch_end_time = GETDATE();

        PRINT '------------------------------------------------------------';
        PRINT ' ✅ Bronze Layer Load Completed Successfully.';
        PRINT ' Rows Inserted: ' + CAST(@rows_inserted AS NVARCHAR(20));
        PRINT ' Duration (sec): ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(10));
        PRINT '============================================================';

        -----------------------------------------------------------------------
        -- 5. Audit Logging
        -----------------------------------------------------------------------
        INSERT INTO load_audit (load_start, load_end, load_mode, table_name, rows_inserted, status)
        VALUES (@batch_start_time, @batch_end_time, 'FULL', 'bronze.sales_raw', @rows_inserted, @load_status);
    END TRY

    BEGIN CATCH
        SET @batch_end_time = GETDATE();
        SET @load_status = 'FAILED';
        SET @error_message = ERROR_MESSAGE();

        PRINT '============================================================';
        PRINT ' ❌ ERROR OCCURRED DURING BRONZE LAYER LOAD';
        PRINT '------------------------------------------------------------';
        PRINT 'Error Message: ' + @error_message;
        PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
        PRINT 'Error State  : ' + CAST(ERROR_STATE() AS NVARCHAR(10));
        PRINT '============================================================';

        -----------------------------------------------------------------------
        -- Log Failure
        -----------------------------------------------------------------------
        INSERT INTO load_audit (load_start, load_end, load_mode, table_name, rows_inserted, status, error_message)
        VALUES (@batch_start_time, @batch_end_time, 'FULL', 'bronze.sales_raw', 0, @load_status, @error_message);

        THROW;
    END CATCH;
END;
GO
