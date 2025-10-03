INSERT INTO SalesDWH.silver.DimDate (DateKey, FullDate, Day, Month, Quarter, Year)
SELECT
    CONVERT(INT, FORMAT(DATEADD(DAY, n, @StartDate), 'yyyyMMdd')) AS DateKey,
    DATEADD(DAY, n, @StartDate) AS FullDate,
    DAY(DATEADD(DAY, n, @StartDate)) AS [Day],
    MONTH(DATEADD(DAY, n, @StartDate)) AS [Month],
    DATEPART(QUARTER, DATEADD(DAY, n, @StartDate)) AS Quarter,
    YEAR(DATEADD(DAY, n, @StartDate)) AS [Year]
FROM N
ORDER BY DateKey;
