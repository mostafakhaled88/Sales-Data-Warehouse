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
