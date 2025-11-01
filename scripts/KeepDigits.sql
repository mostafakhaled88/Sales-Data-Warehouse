CREATE FUNCTION dbo.KeepDigits (@input NVARCHAR(4000))
RETURNS NVARCHAR(4000)
AS
BEGIN
    DECLARE @output NVARCHAR(4000);

    WITH Tally AS (
        SELECT TOP (LEN(@input)) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.objects
    )
    SELECT @output = STRING_AGG(SUBSTRING(@input, n, 1), '')
    FROM Tally
    WHERE SUBSTRING(@input, n, 1) LIKE '[0-9]';

    RETURN @output;
END;
