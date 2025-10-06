USE SalesDWH;
GO

IF OBJECT_ID('gold.vw_SalesSummary', 'V') IS NOT NULL
    DROP VIEW gold.vw_SalesSummary;
GO

CREATE VIEW gold.vw_SalesSummary
AS
SELECT 
    d.YearName AS [Year],
    d.MonthName AS [Month],
    p.ProductLine,
    p.ProductCode,
    SUM(f.QuantityOrdered) AS TotalQuantity,
    SUM(f.Sales) AS TotalSales,
    ROUND(AVG(f.PriceEach), 2) AS AvgUnitPrice
FROM silver.FactSales f
JOIN silver.DimDate d ON f.DateID = d.DateID
JOIN silver.DimProduct p ON f.ProductID = p.ProductID
GROUP BY 
    d.YearName, d.MonthName, 
    p.ProductLine, p.ProductCode;
GO






IF OBJECT_ID('gold.vw_ProductPerformance', 'V') IS NOT NULL
    DROP VIEW gold.vw_ProductPerformance;
GO

CREATE VIEW gold.vw_ProductPerformance
AS
SELECT
    p.ProductLine,
    p.ProductCode,
    p.MSRP,
    SUM(f.Sales) AS TotalRevenue,
    SUM(f.QuantityOrdered) AS TotalUnitsSold,
    ROUND(AVG(f.PriceEach), 2) AS AvgSellingPrice,
    ROUND(SUM(f.Sales) / NULLIF(SUM(f.QuantityOrdered), 0), 2) AS RevenuePerUnit
FROM silver.FactSales f
JOIN silver.DimProduct p ON f.ProductID = p.ProductID
GROUP BY
    p.ProductLine, p.ProductCode, p.MSRP;
GO




IF OBJECT_ID('gold.vw_CustomerInsights', 'V') IS NOT NULL
    DROP VIEW gold.vw_CustomerInsights;
GO

CREATE VIEW gold.vw_CustomerInsights
AS
SELECT
    c.CustomerID,
    c.CustomerName,
    c.Country,
    c.Territory,
    COUNT(DISTINCT f.OrderNumber) AS TotalOrders,
    SUM(f.Sales) AS TotalSpent,
    SUM(f.QuantityOrdered) AS TotalItemsPurchased,
    ROUND(AVG(f.PriceEach), 2) AS AvgPricePerItem
FROM silver.FactSales f
JOIN silver.DimCustomer c ON f.CustomerID = c.CustomerID
GROUP BY
    c.CustomerID, c.CustomerName, c.Country, c.Territory;
GO





IF OBJECT_ID('gold.vw_RegionalPerformance', 'V') IS NOT NULL
    DROP VIEW gold.vw_RegionalPerformance;
GO

CREATE VIEW gold.vw_RegionalPerformance
AS
SELECT
    c.Country,
    c.Territory,
    d.YearName AS [Year],
    d.MonthName AS [Month],
    SUM(f.Sales) AS TotalSales,
    SUM(f.QuantityOrdered) AS TotalQuantity,
    COUNT(DISTINCT f.CustomerID) AS ActiveCustomers
FROM silver.FactSales f
JOIN silver.DimCustomer c ON f.CustomerID = c.CustomerID
JOIN silver.DimDate d ON f.DateID = d.DateID
GROUP BY
    c.Country, c.Territory, d.YearName, d.MonthName;
GO


