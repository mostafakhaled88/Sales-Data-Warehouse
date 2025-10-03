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
	ContactFirstName NVARCHAR(100) NULL,
	ContactLastName NVARCHAR(100) NULL,
    CONSTRAINT FK_DimCustomer_DimLocation FOREIGN KEY (LocationKey)
        REFERENCES [SalesDWH].[silver].[DimLocation](LocationKey)
);





INSERT INTO [SalesDWH].[silver].[DimCustomer] 
    (CustomerName, Phone, AddressLine, ContactFirstName, LocationKey)
SELECT DISTINCT
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([CUSTOMERNAME], '+', ''), '(', ''), ')', ''), '"', ''), '.', ''), ',', ''), '/', '') AS CustomerName,
    CASE 
        WHEN PATINDEX('%[0-9]%', REPLACE([PHONE], '+','')) = 0 THEN 'Unknown'
        ELSE REPLACE(REPLACE(REPLACE([PHONE], '+',''), '(',''),')','')
    END AS Phone,
    COALESCE(NULLIF(LTRIM(RTRIM(REPLACE([ADDRESSLINE1], '"',''))), ''), 
             NULLIF(LTRIM(RTRIM(REPLACE([ADDRESSLINE2], '"',''))), '')) AS AddressLine,
    CASE 
        WHEN CONTACTFIRSTNAME IS NULL OR LTRIM(RTRIM(CONTACTFIRSTNAME)) = '' THEN 'Unknown'
        WHEN CONTACTFIRSTNAME LIKE '%EMEA%' OR CONTACTFIRSTNAME LIKE '%APAC%' OR CONTACTFIRSTNAME LIKE '%NA%'
             OR CONTACTFIRSTNAME LIKE '%Japan%' OR CONTACTFIRSTNAME LIKE '%Citeaux%'
             OR CONTACTFIRSTNAME LIKE '%France%' OR CONTACTFIRSTNAME LIKE '%Germany%'
             OR CONTACTFIRSTNAME LIKE '%Spain%' OR CONTACTFIRSTNAME LIKE '%USA%'
             OR CONTACTFIRSTNAME LIKE '%UK%' OR CONTACTFIRSTNAME LIKE '%Sweden%'
             OR CONTACTFIRSTNAME LIKE '%Norway%' OR CONTACTFIRSTNAME LIKE '%Singapore%' THEN 'Unknown'
        WHEN PATINDEX('%[0-9]%', CONTACTFIRSTNAME) > 0 THEN 'Unknown'
        ELSE LTRIM(RTRIM(CONTACTFIRSTNAME))
    END AS ContactFirstName,
    l.LocationKey
FROM [SalesDWH].[bronze].[sales_raw] b
INNER JOIN [SalesDWH].[silver].[dimLocation] l
    ON ISNULL(NULLIF(LTRIM(RTRIM(b.City)), ''), 'Unknown') = l.City
   AND ISNULL(NULLIF(LTRIM(RTRIM(b.PostalCode)), ''), 'Unknown') = l.PostalCode
   AND ISNULL(NULLIF(LTRIM(RTRIM(b.Country)), ''), 'Unknown') = l.Country;
