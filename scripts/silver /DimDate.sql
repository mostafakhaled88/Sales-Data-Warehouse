DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate DATE   = '2030-12-31';

;WITH N AS
(
    -- Generate numbers using system views (up to ~1M rows)
    SELECT TOP (DATEDIFF(DAY, @StartDate, @EndDate) + 1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.objects
)
INSERT INTO SalesDWH.silver.DimDate
       (DateKey, FullDate, [Day], [Month], Quarter, [Year])
SELECT
    CONVERT(INT, FORMAT(DATEADD(DAY, n, @StartDate), 'yyyyMMdd')) AS DateKey,
    DATEADD(DAY, n, @StartDate)                                   AS FullDate,
    DAY(DATEADD(DAY, n, @StartDate))                              AS [Day],
    MONTH(DATEADD(DAY, n, @StartDate))                            AS [Month],
    DATEPART(QUARTER, DATEADD(DAY, n, @StartDate))                AS Quarter,
    YEAR(DATEADD(DAY, n, @StartDate))                             AS [Year]
FROM N
ORDER BY DateKey;
