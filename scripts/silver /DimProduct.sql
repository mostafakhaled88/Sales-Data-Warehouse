/* ===========================================================
   2. Populate DimProduct
   =========================================================== */
INSERT INTO [SalesDWH].[silver].[DimProduct] 
    (ProductCode, ProductLine, MSRP)
SELECT DISTINCT
    LTRIM(RTRIM(ISNULL([ProductCode], 'Unknown'))) AS ProductCode,
    LTRIM(RTRIM([ProductLine])) AS ProductLine,
    TRY_CAST([MSRP] AS DECIMAL(10,2)) AS MSRP
FROM [SalesDWH].[bronze].[sales_raw]
WHERE ProductCode IS NOT NULL;
