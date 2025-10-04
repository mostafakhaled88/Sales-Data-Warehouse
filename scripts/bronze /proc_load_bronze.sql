/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/

USE SalesDWH;
GO

IF OBJECT_ID('bronze.load_bronze', 'P') IS NOT NULL
    DROP PROCEDURE bronze.load_bronze;
GO

CREATE PROCEDURE bronze.load_bronze as

	BEGIN
		DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME; 
		BEGIN TRY
			SET @batch_start_time = GETDATE();
			PRINT '================================================';
			PRINT 'Loading Bronze Layer';
			PRINT '================================================';

		

		-- Truncate existing data
		TRUNCATE TABLE bronze.sales_raw;

		-- Bulk insert from CSV
		BULK INSERT [SalesDWH].[bronze].[sales_raw]
FROM 'C:\SQLData\sales_data_cleaned.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);


		PRINT ' Bronze Load Completed Successfully.';
	SET @batch_end_time = GETDATE();
			PRINT '=========================================='
			PRINT 'Loading Bronze Layer is Completed';
			PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
			PRINT '=========================================='
		END TRY
		BEGIN CATCH
			PRINT '=========================================='
			PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
			PRINT 'Error Message' + ERROR_MESSAGE();
			PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
			PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
			PRINT '=========================================='
		END CATCH
	END
