USE SalesDWH;
GO

-------------------------------------------------------------------
-- 1. Drop Existing Tables (Order matters due to FKs)
-------------------------------------------------------------------
IF OBJECT_ID('SalesDWH.silver.FactSales', 'U') IS NOT NULL
    DROP TABLE SalesDWH.silver.FactSales;
IF OBJECT_ID('SalesDWH.silver.DimCustomer', 'U') IS NOT NULL
    DROP TABLE SalesDWH.silver.DimCustomer;
IF OBJECT_ID('SalesDWH.silver.DimProduct', 'U') IS NOT NULL
    DROP TABLE SalesDWH.silver.DimProduct;
IF OBJECT_ID('SalesDWH.silver.DimDate', 'U') IS NOT NULL
    DROP TABLE SalesDWH.silver.DimDate;
GO

-------------------------------------------------------------------
-- 2. DimDate
-------------------------------------------------------------------
CREATE TABLE SalesDWH.silver.DimDate
(
    DateID INT IDENTITY(1,1) PRIMARY KEY,
    FullDate DATE,
    Day INT,
    Month_ID INT,
    MonthName NVARCHAR(20),
    Qtr_ID INT,
    QuarterName NVARCHAR(10),
    Year_ID INT,
    YearName NVARCHAR(10),
    dwh_create_date DATETIME DEFAULT GETDATE()
);
GO

-------------------------------------------------------------------
-- 3. DimCustomer
-------------------------------------------------------------------
CREATE TABLE SalesDWH.silver.DimCustomer
(
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(255),
    ContactFirstName NVARCHAR(100),
    ContactLastName NVARCHAR(100),
    Phone NVARCHAR(50),
    AddressLine1 NVARCHAR(255),
    City NVARCHAR(100),
    State NVARCHAR(100),
    PostalCode NVARCHAR(20),
    Country NVARCHAR(100),
    Territory NVARCHAR(50),
    dwh_create_date DATETIME DEFAULT GETDATE()
);
GO

-------------------------------------------------------------------
-- 4. DimProduct
-------------------------------------------------------------------
CREATE TABLE SalesDWH.silver.DimProduct
(
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductCode NVARCHAR(50),
    ProductLine NVARCHAR(100),
    MSRP DECIMAL(10,2),
    dwh_create_date DATETIME DEFAULT GETDATE()
);
GO

-------------------------------------------------------------------
-- 5. FactSales (with FKs to all dimensions)
-------------------------------------------------------------------
CREATE TABLE SalesDWH.silver.FactSales
(
    SalesID INT IDENTITY(1,1) PRIMARY KEY,
    OrderNumber INT,
    OrderDate DATETIME,
    Status NVARCHAR(50),
    QuantityOrdered INT,
    PriceEach DECIMAL(10,2),
    Sales DECIMAL(18,2),
    DealSize NVARCHAR(20),

    -- Foreign Key Columns
    CustomerID INT,
    ProductID INT,
    DateID INT,         -- Connects to DimDate
    Qtr_ID INT,
    Month_ID INT,
    Year_ID INT,

    dwh_create_date DATETIME DEFAULT GETDATE(),

    -------------------------------------------------------------------
    -- Foreign Key Constraints
    -------------------------------------------------------------------
    CONSTRAINT FK_FactSales_DimCustomer
        FOREIGN KEY (CustomerID)
        REFERENCES SalesDWH.silver.DimCustomer(CustomerID),

    CONSTRAINT FK_FactSales_DimProduct
        FOREIGN KEY (ProductID)
        REFERENCES SalesDWH.silver.DimProduct(ProductID),

    CONSTRAINT FK_FactSales_DimDate
        FOREIGN KEY (DateID)
        REFERENCES SalesDWH.silver.DimDate(DateID)
);
GO
