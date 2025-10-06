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
      EXEC bronze.load_bronze;
===============================================================================*/

USE SalesDWH;
GO

IF OBJECT_ID('bronze.load_bronze', 'P') IS NOT NULL
    DROP PROCEDURE bronze.load_bronze;
GO

CREATE PROCEDURE bronze.load_bronze
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @batch_start_time DATETIME,
        @batch_end_time DATETIME,
        @rows_inserted INT;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '============================================================';
        PRINT ' Starting Bronze Layer Load...';
        PRINT '============================================================';

        -----------------------------------------------------------------------
        -- 1. Truncate Existing Data
        -----------------------------------------------------------------------
        PRINT ' Truncating existing data in [bronze].[sales_raw]...';
        TRUNCATE TABLE [bronze].[sales_raw];

        -----------------------------------------------------------------------
        -- 2. Bulk Insert Data from CSV File
        -----------------------------------------------------------------------
        PRINT ' Loading data from CSV file into [bronze].[sales_raw]...';

        BULK INSERT [SalesDWH].[bronze].[sales_raw]
        FROM 'C:\SQLData\sales_data_cleaned.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );

        -----------------------------------------------------------------------
        -- 3. Row Count Summary
        -----------------------------------------------------------------------
        SELECT @rows_inserted = COUNT(*) FROM [bronze].[sales_raw];

        -----------------------------------------------------------------------
        -- 4. Completion Summary
        -----------------------------------------------------------------------
        SET @batch_end_time = GETDATE();

        PRINT ' Bronze Layer Load Completed Successfully.';
        PRINT '------------------------------------------------------------';
        PRINT ' Rows Inserted: ' + CAST(@rows_inserted AS NVARCHAR(20) );
        PRINT ' Load Duration: ' 
              + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(10)) 
              + ' seconds';
        PRINT '============================================================';
    END TRY

    BEGIN CATCH
        PRINT '============================================================';
        PRINT ' ERROR OCCURRED DURING BRONZE LAYER LOAD';
        PRINT '------------------------------------------------------------';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
        PRINT 'Error State  : ' + CAST(ERROR_STATE() AS NVARCHAR(10));
        PRINT '============================================================';
    END CATCH
END;
GO

