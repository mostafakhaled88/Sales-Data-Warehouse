USE SalesDWH;
GO

IF OBJECT_ID('SalesDWH.silver.DimCustomer', 'U') IS NOT NULL
    DROP TABLE SalesDWH.silver.DimCustomer;
GO

CREATE TABLE SalesDWH.silver.DimCustomer
(
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(255),
    ContactFirstName NVARCHAR(100),
    ContactLastName NVARCHAR(100),
    Phone NVARCHAR(50),
    AddressLine1 NVARCHAR(255),
    AddressLine2 NVARCHAR(255),
    City NVARCHAR(100),
    State NVARCHAR(100),
    PostalCode NVARCHAR(20),
    Country NVARCHAR(100),
    Territory NVARCHAR(50),
    DealSize NVARCHAR(20),
    dwh_create_date DATETIME DEFAULT GETDATE()
);
GO

IF OBJECT_ID('SalesDWH.silver.DimProduct', 'U') IS NOT NULL
    DROP TABLE SalesDWH.silver.DimProduct;
GO

CREATE TABLE SalesDWH.silver.DimProduct
(
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductCode NVARCHAR(50),
    ProductLine NVARCHAR(100),
    MSRP DECIMAL(10,2),
    dwh_create_date DATETIME DEFAULT GETDATE()
);
GO


IF OBJECT_ID('SalesDWH.silver.FactSales', 'U') IS NOT NULL
    DROP TABLE SalesDWH.silver.FactSales;
GO

CREATE TABLE SalesDWH.silver.FactSales
(
    SalesID INT IDENTITY(1,1) PRIMARY KEY,
    OrderNumber INT,
    OrderDate DATETIME,
    Status NVARCHAR(50),
    QuantityOrdered INT,
    PriceEach DECIMAL(10,2),
    Sales DECIMAL(18,2),
    Qtr_ID INT,
    Month_ID INT,
    Year_ID INT,
    ProductCode NVARCHAR(50),
    dwh_create_date DATETIME DEFAULT GETDATE()
);
GO
