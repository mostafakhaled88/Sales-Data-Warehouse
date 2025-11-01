/*===============================================================================
  Stored Procedure: bronze.load_bronze
  ===============================================================================
  Purpose:
      Loads data into the Bronze Layer (incremental or full) from external CSV files.

  Features:
      - Supports FULL and INCREMENTAL load modes.
      - Uses a temporary staging table for comparison.
      - Displays a clean, structured summary (UNION ALL format).
      - Logs all operations in load_audit and load_errors tables.

  Usage:
      EXEC bronze.load_bronze @FilePath = 'C:\SQLData\sales_data.csv', @LoadMode = 'FULL';
      EXEC bronze.load_bronze @FilePath = 'C:\SQLData\sales_data.csv', @LoadMode = 'INCR';
===============================================================================*/

USE SalesDWH;
GO

IF OBJECT_ID('bronze.load_bronze', 'P') IS NOT NULL
    DROP PROCEDURE bronze.load_bronze;
GO

CREATE PROCEDURE bronze.load_bronze
    @FilePath NVARCHAR(255),
    @LoadMode NVARCHAR(10) = 'INCR'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @batch_start_time DATETIME = GETDATE(),
        @batch_end_time DATETIME,
        @rows_before_load INT = 0,
        @rows_in_file INT = 0,
        @rows_inserted INT = 0,
        @rows_existing INT = 0,
        @rows_total INT = 0,
        @duration_seconds INT,
        @error_message NVARCHAR(MAX),
        @load_status NVARCHAR(20) = 'SUCCESS',
        @sql NVARCHAR(MAX);

    BEGIN TRY
        PRINT '============================================================';
        PRINT 'Starting Bronze Layer Load (' + @LoadMode + ' Mode)';
        PRINT '============================================================';
        PRINT 'File Path: ' + @FilePath;
        PRINT '------------------------------------------------------------';

        -----------------------------------------------------------------------
        -- 1. Validate Parameters
        -----------------------------------------------------------------------
        IF @FilePath IS NULL OR LTRIM(RTRIM(@FilePath)) = ''
            THROW 50001, 'File path cannot be NULL or empty.', 1;

        IF @LoadMode NOT IN ('FULL', 'INCR')
            THROW 50002, 'Invalid LoadMode. Use FULL or INCR.', 1;

        -----------------------------------------------------------------------
        -- 2. Capture current row count before load
        -----------------------------------------------------------------------
        SELECT @rows_before_load = COUNT(*) FROM bronze.sales_raw;

        -----------------------------------------------------------------------
        -- 3. Handle FULL load truncation
        -----------------------------------------------------------------------
        IF @LoadMode = 'FULL'
        BEGIN
            PRINT 'Performing FULL LOAD: Truncating [bronze].[sales_raw]...';
            TRUNCATE TABLE bronze.sales_raw;
            SET @rows_before_load = 0;
        END;

        -----------------------------------------------------------------------
        -- 4. Load CSV into staging table
        -----------------------------------------------------------------------
        PRINT 'Loading data from CSV into temporary staging table...';

        IF OBJECT_ID('tempdb..#staging_sales_raw') IS NOT NULL
            DROP TABLE #staging_sales_raw;

        CREATE TABLE #staging_sales_raw (
            order_number         INT,
            quantity_ordered     INT,
            price_each           DECIMAL(10,2),
            order_line_number    INT,
            order_date           VARCHAR(50),
            status               VARCHAR(50),
            qtr_id               INT,
            month_id             INT,
            year_id              INT,
            product_line         VARCHAR(100),
            msrp                 INT,
            product_code         VARCHAR(50),
            customer_name        VARCHAR(255),
            phone                VARCHAR(50),
            address_line1        VARCHAR(255),
            address_line2        VARCHAR(255),
            city                 VARCHAR(100),
            state                VARCHAR(100),
            postal_code          VARCHAR(20),
            country              VARCHAR(100),
            territory            VARCHAR(100),
            contact_last_name    VARCHAR(100),
            contact_first_name   VARCHAR(100),
            deal_size            VARCHAR(50)
        );

        SET @sql = N'
            BULK INSERT #staging_sales_raw
            FROM ''' + @FilePath + N'''
            WITH (
                FORMAT = ''CSV'',
                FIRSTROW = 2,
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''\n'',
                TABLOCK
            );';
        EXEC sp_executesql @sql;

        SELECT @rows_in_file = COUNT(*) FROM #staging_sales_raw;

        PRINT 'Rows Found in File: ' + CAST(@rows_in_file AS NVARCHAR(20));
        PRINT '------------------------------------------------------------';

        -----------------------------------------------------------------------
        -- 5. Load Logic
        -----------------------------------------------------------------------
        IF @LoadMode = 'INCR'
        BEGIN
            PRINT 'Performing INCREMENTAL LOAD: Inserting only new records...';

            INSERT INTO bronze.sales_raw (
                order_number, quantity_ordered, price_each, order_line_number,
                order_date, status, qtr_id, month_id, year_id, product_line,
                msrp, product_code, customer_name, phone, address_line1, address_line2,
                city, state, postal_code, country, territory,
                contact_last_name, contact_first_name, deal_size, load_dtm
            )
            SELECT s.*, GETDATE()
            FROM #staging_sales_raw s
            WHERE NOT EXISTS (
                SELECT 1
                FROM bronze.sales_raw b
                WHERE b.order_number = s.order_number
                  AND b.order_line_number = s.order_line_number
            );

            SET @rows_inserted = @@ROWCOUNT;
            SET @rows_existing = @rows_in_file - @rows_inserted;
        END
        ELSE
        BEGIN
            PRINT 'Performing FULL LOAD: Inserting all rows...';

            INSERT INTO bronze.sales_raw (
                order_number, quantity_ordered, price_each, order_line_number,
                order_date, status, qtr_id, month_id, year_id, product_line,
                msrp, product_code, customer_name, phone, address_line1, address_line2,
                city, state, postal_code, country, territory,
                contact_last_name, contact_first_name, deal_size, load_dtm
            )
            SELECT s.*, GETDATE()
            FROM #staging_sales_raw s;

            SET @rows_inserted = @@ROWCOUNT;
            SET @rows_existing = 0;
        END;

        SELECT @rows_total = COUNT(*) FROM bronze.sales_raw;

        -----------------------------------------------------------------------
        -- 6. Summary (UNION ALL format)
        -----------------------------------------------------------------------
        SET @batch_end_time = GETDATE();
        SET @duration_seconds = DATEDIFF(SECOND, @batch_start_time, @batch_end_time);

        PRINT '-----------------------------------------------------------';
        PRINT '-- Bronze Layer Load Summary (' + @LoadMode + ' Mode)';
        PRINT '-----------------------------------------------------------';

        SELECT 
            'File Path' AS Metric, @FilePath AS Value
        UNION ALL SELECT 
            'Load Type', @LoadMode
	    UNION ALL SELECT 
            'Rows Existing ', CAST(@rows_existing AS NVARCHAR(20))
        UNION ALL SELECT 
            'Rows Inserted', CAST(@rows_inserted AS NVARCHAR(20))
        UNION ALL SELECT 
            'Total Rows After Load', CAST(@rows_total AS NVARCHAR(20))
        UNION ALL SELECT 
            'Duration (seconds)', CAST(@duration_seconds AS NVARCHAR(10))
        UNION ALL SELECT 
            'Completion Time', CONVERT(NVARCHAR(30), @batch_end_time, 126);

        PRINT '-----------------------------------------------------------';
        PRINT 'Bronze Load Completed Successfully ✅';
        PRINT '============================================================';

        -----------------------------------------------------------------------
        -- 7. Audit Logging
        -----------------------------------------------------------------------
        INSERT INTO dbo.load_audit (load_start, load_end, load_mode, table_name, rows_inserted, status)
        VALUES (@batch_start_time, @batch_end_time, @LoadMode, 'bronze.sales_raw', @rows_inserted, @load_status);
    END TRY

    BEGIN CATCH
        -----------------------------------------------------------------------
        -- Error Handling
        -----------------------------------------------------------------------
        SET @batch_end_time = GETDATE();
        SET @load_status = 'FAILED';
        SET @error_message = ERROR_MESSAGE();

        PRINT '============================================================';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER LOAD';
        PRINT 'Error Message: ' + @error_message;
        PRINT '============================================================';

        INSERT INTO dbo.load_audit (load_start, load_end, load_mode, table_name, rows_inserted, status, error_message)
        VALUES (@batch_start_time, @batch_end_time, @LoadMode, 'bronze.sales_raw', 0, @load_status, @error_message);

        INSERT INTO dbo.load_errors (table_name, error_message, record_data)
        VALUES ('bronze.sales_raw', @error_message, NULL);

        THROW;
    END CATCH;
END;
GO

PRINT 'Procedure [bronze.load_bronze] created successfully.';
GO
