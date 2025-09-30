# 📖 Data Catalog – CompanySales Data Warehouse

This document describes the source tables, columns, and relationships for the **Sales Data Warehouse** project.  
It serves as a reference for data engineers, analysts, and dashboard developers.

---

## 1. Customer Table

**Description**: Stores customer demographic and contact details.  
**Primary Key**: `Id`

| Column     | Type     | Description                        | Notes       |
|------------|----------|------------------------------------|-------------|
| Id         | INT      | Unique customer identifier         | PK          |
| FirstName  | VARCHAR  | Customer first name                |             |
| LastName   | VARCHAR  | Customer last name                 |             |
| City       | VARCHAR  | City of residence                  |             |
| Country    | VARCHAR  | Country of residence               |             |
| Phone      | VARCHAR  | Customer’s phone number            |             |

---

## 2. Order Table

**Description**: Contains high-level sales order details.  
**Primary Key**: `Id`  
**Foreign Keys**: `CustomerId → Customer(Id)`

| Column      | Type     | Description                        | Notes       |
|-------------|----------|------------------------------------|-------------|
| Id          | INT      | Unique order identifier            | PK          |
| OrderDate   | DATE     | Date when the order was placed     |             |
| OrderNumber | VARCHAR  | Business reference number          | Business Key|
| CustomerId  | INT      | FK → Customer(Id)                  |             |
| TotalAmount | DECIMAL  | Total value of the order           |             |

---

## 3. OrderItem Table

**Description**: Stores line items for each order.  
**Primary Key**: `Id`  
**Foreign Keys**: `OrderId → Order(Id)`, `ProductId → Product(Id)`

| Column    | Type     | Description                        | Notes       |
|-----------|----------|------------------------------------|-------------|
| Id        | INT      | Unique order item identifier       | PK          |
| OrderId   | INT      | FK → Order(Id)                     |             |
| ProductId | INT      | FK → Product(Id)                   |             |
| UnitPrice | DECIMAL  | Price per unit at sale time        |             |
| Quantity  | INT      | Number of units ordered            |             |

---

## 4. Product Table

**Description**: Contains details of products offered for sale.  
**Primary Key**: `Id`  
**Foreign Keys**: `SupplierId → Supplier(Id)`

| Column         | Type     | Description                        | Notes       |
|----------------|----------|------------------------------------|-------------|
| Id             | INT      | Unique product identifier          | PK          |
| ProductName    | VARCHAR  | Name of the product                |             |
| SupplierId     | INT      | FK → Supplier(Id)                  |             |
| UnitPrice      | DECIMAL  | Price per unit                     |             |
| Package        | VARCHAR  | Packaging description              |             |
| IsDiscontinued | BIT      | Whether the product is discontinued| Boolean flag|

---

## 5. Supplier Table

**Description**: Stores supplier details and contacts.  
**Primary Key**: `Id`

| Column       | Type     | Description                        | Notes       |
|--------------|----------|------------------------------------|-------------|
| Id           | INT      | Unique supplier identifier         | PK          |
| CompanyName  | VARCHAR  | Supplier company name              |             |
| ContactName  | VARCHAR  | Contact person’s name              |             |
| ContactTitle | VARCHAR  | Title of the contact person        |             |
| City         | VARCHAR  | City of the supplier               |             |
| Country      | VARCHAR  | Country of the supplier            |             |
| Phone        | VARCHAR  | Phone number                       |             |
| Fax          | VARCHAR  | Fax number                         |             |

---

## 🔗 Relationships

- **Customer (1) → (M) Order**  
- **Order (1) → (M) OrderItem**  
- **Product (1) → (M) OrderItem**  
- **Supplier (1) → (M) Product**

---

## 📊 Usage

This catalog supports building a **Sales Data Warehouse** with a **star schema**:  
- **Fact Table**: `OrderItem` (measures: Quantity, UnitPrice, TotalAmount)  
- **Dimension Tables**: `Customer`, `Order (Date Dimension)`, `Product`, `Supplier`  

The cleaned and transformed model powers **Power BI dashboards** for sales insights.
