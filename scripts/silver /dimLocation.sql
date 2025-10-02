INSERT INTO [SalesDWH].[silver].[dimLocation] (City, PostalCode, Country, Territory)
SELECT DISTINCT
    -- City Cleaning
    CASE
        WHEN CITY IS NULL 
             OR LTRIM(RTRIM(CITY)) = '' 
             OR CITY LIKE '%[0-9]%' 
             OR CITY LIKE '%Floor%' 
             OR CITY LIKE '%Level%' 
             OR CITY LIKE '%PB%' 
             OR CITY LIKE '%Apt%' 
             OR CITY LIKE '%/' 
             OR CITY LIKE 'rue du Commerce'
        THEN 'Unknown'
        WHEN CITY = 'NYC' THEN 'New York'
        ELSE LTRIM(RTRIM(REPLACE(CITY, '"', '')))
    END AS City,

    -- Postal Code Cleaning
    CASE
        WHEN Postalcode IS NULL OR LTRIM(RTRIM(Postalcode)) = '' THEN 'Unknown'
        WHEN PATINDEX('%[0-9]%', Postalcode) = 0 THEN 'Unknown'
        ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([Postalcode], '+',''), '(',''),')',''),'"',''),'.',''),',',''),'/','')
    END AS PostalCode,

    -- Country Cleaning
    CASE
        WHEN COUNTRY IS NULL OR LTRIM(RTRIM(COUNTRY)) = '' THEN 'Unknown'
        WHEN ISNUMERIC(COUNTRY) = 1 THEN 'Unknown'
        WHEN COUNTRY LIKE '%[0-9]%' THEN 'Unknown'
        WHEN COUNTRY IN ('Osaka', 'Tokyo', 'Sevilla', 'Paris', 'Lyon', 'Madrid') THEN 'Unknown'
        ELSE LTRIM(RTRIM(COUNTRY))
    END AS Country,

    -- Territory Mapping
    CASE
        WHEN COUNTRY IN ('USA','Canada') THEN 'NA'
        WHEN COUNTRY IN ('France','Germany','UK','Spain','Belgium',
                         'Switzerland','Austria','Ireland','Norway',
                         'Sweden','Finland','Italy','Denmark') THEN 'EMEA'
        WHEN COUNTRY IN ('Japan','Australia','Singapore','Philippines','China','India') THEN 'APAC'
        ELSE 'Unknown'
    END AS Territory
FROM [SalesDWH].[bronze].[sales_raw];
