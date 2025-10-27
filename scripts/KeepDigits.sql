USE SalesDWH;
GO

IF OBJECT_ID('dbo.KeepDigits', 'FN') IS NOT NULL
    DROP FUNCTION dbo.KeepDigits;
GO

CREATE FUNCTION dbo.KeepDigits (@input NVARCHAR(100))
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @output NVARCHAR(100) = '';
    DECLARE @i INT = 1;

    WHILE @i <= LEN(@input)
    BEGIN
        IF SUBSTRING(@input, @i, 1) LIKE '[0-9]'
            SET @output += SUBSTRING(@input, @i, 1);
        SET @i += 1;
    END

    RETURN @output;
END;
GO
