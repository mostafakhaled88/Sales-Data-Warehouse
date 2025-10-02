-- 1. Drop referencing constraints first
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += 'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) 
             + '.' + QUOTENAME(OBJECT_NAME(parent_object_id)) 
             + ' DROP CONSTRAINT ' + QUOTENAME(name) + ';' + CHAR(13)
FROM sys.foreign_keys
WHERE referenced_object_id = OBJECT_ID('SalesDWH.silver.DimCustomer');

EXEC sp_executesql @sql;

-- 2. Drop the table
IF OBJECT_ID('SalesDWH.silver.DimCustomer', 'U') IS NOT NULL
    DROP TABLE SalesDWH.silver.DimCustomer;
GO

-- 3. Recreate table
CREATE TABLE [SalesDWH].[silver].[DimCustomer] (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(200) NOT NULL,
    Phone NVARCHAR(50) NULL,
    AddressLine NVARCHAR(250) NULL,
    LocationKey INT NOT NULL,
    CONSTRAINT FK_DimCustomer_DimLocation FOREIGN KEY (LocationKey)
        REFERENCES [SalesDWH].[silver].[DimLocation](LocationKey)
);




INSERT INTO [SalesDWH].[silver].[dimCustomer] 
    (CustomerName, Phone, AddressLine, LocationKey)
SELECT DISTINCT
    -- Cleaned Customer Name
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([CUSTOMERNAME], '+', ''), '(', ''), ')', ''), '"', ''), '.', ''), ',', ''), '/', '') AS CustomerName,

    -- Phone
    CASE 
        WHEN PATINDEX('%[0-9]%', REPLACE([PHONE], '+','')) = 0 THEN 'Unknown'
        ELSE REPLACE(REPLACE(REPLACE([PHONE], '+',''), '(',''),')','')
    END AS Phone,

    -- One Address line
    COALESCE(NULLIF(LTRIM(RTRIM(REPLACE([ADDRESSLINE1], '"',''))), ''),
             NULLIF(LTRIM(RTRIM(REPLACE([ADDRESSLINE2], '"',''))), '')) AS AddressLine,

    -- LocationKey (lookup join)
    l.LocationKey
FROM [SalesDWH].[bronze].[sales_raw] b
INNER JOIN [SalesDWH].[silver].[dimLocation] l
    ON ISNULL(NULLIF(LTRIM(RTRIM(b.City)), ''), 'Unknown') = l.City
   AND ISNULL(NULLIF(LTRIM(RTRIM(b.PostalCode)), ''), 'Unknown') = l.PostalCode
   AND ISNULL(NULLIF(LTRIM(RTRIM(b.Country)), ''), 'Unknown') = l.Country;
