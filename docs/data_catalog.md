# 🗂️ Data Catalog – Gold Layer (Sales Data Warehouse)

## 📘 Overview
The **Gold Layer** represents the **business-ready** data models and aggregated views built on top of the **Silver Layer**.  
These views are optimized for reporting, analytics, and Power BI dashboards.  

**Naming Convention:**  
All object names follow `snake_case` (lowercase letters with underscores).  
Example: `vw_sales_summary`

---

## 📂 Schema: `SalesDWH.gold`

### 1. `vw_sales_summary`
**Description:**  
Aggregated view combining facts and dimensions to present total sales, quantities, and revenue metrics for analysis.

**Source Tables:**  
- `silver.fact_sales`  
- `silver.dim_customer`  
- `silver.dim_product`  
- `silver.dim_date`

**Columns:**
| Column Name | Data Type | Description |
|--------------|------------|--------------|
| order_number | INT | Unique sales order identifier |
| order_date | DATE | Date of the sale |
| customer_name | NVARCHAR(255) | Customer who made the purchase |
| product_name | NVARCHAR(255) | Product sold |
| product_line | NVARCHAR(255) | Product category/line |
| quantity_ordered | INT | Units sold |
| price_each | DECIMAL(10,2) | Unit price per product |
| total_sales | DECIMAL(18,2) | Total sales amount (quantity × price) |
| country | NVARCHAR(100) | Customer’s country |
| state | NVARCHAR(100) | Customer’s state or region |
| year | INT | Sales year |
| month | NVARCHAR(50) | Sales month |
| quarter | NVARCHAR(10) | Quarter (Q1–Q4) |

---

### 2. `vw_product_performance`
**Description:**  
Summarizes product-level metrics for performance tracking and profitability analysis.

**Source Tables:**  
- `silver.fact_sales`  
- `silver.dim_product`  
- `silver.dim_date`

**Columns:**
| Column Name | Data Type | Description |
|--------------|------------|--------------|
| product_code | NVARCHAR(50) | Unique product identifier |
| product_name | NVARCHAR(255) | Product name |
| product_line | NVARCHAR(255) | Product category |
| total_quantity_sold | INT | Total number of units sold |
| total_revenue | DECIMAL(18,2) | Total sales value |
| avg_price | DECIMAL(10,2) | Average selling price |
| year | INT | Year of sale |
| month | NVARCHAR(50) | Month of sale |

---

### 3. `vw_customer_sales`
**Description:**  
Provides a customer-centric view showing purchase history, frequency, and total sales contribution.

**Source Tables:**  
- `silver.fact_sales`  
- `silver.dim_customer`  
- `silver.dim_date`

**Columns:**
| Column Name | Data Type | Description |
|--------------|------------|--------------|
| customer_id | INT | Unique customer identifier |
| customer_name | NVARCHAR(255) | Customer full name |
| country | NVARCHAR(100) | Customer country |
| state | NVARCHAR(100) | Customer region or state |
| total_orders | INT | Number of sales orders placed |
| total_sales | DECIMAL(18,2) | Total purchase amount |
| avg_order_value | DECIMAL(18,2) | Average value per order |
| first_order_date | DATE | Date of first recorded order |
| last_order_date | DATE | Most recent order date |

---

### 4. `vw_region_sales`
**Description:**  
Provides aggregated regional metrics for geographical analysis.

**Source Tables:**  
- `silver.fact_sales`  
- `silver.dim_customer`  
- `silver.dim_date`

**Columns:**
| Column Name | Data Type | Description |
|--------------|------------|--------------|
| country | NVARCHAR(100) | Country name |
| state | NVARCHAR(100) | State or province |
| total_sales | DECIMAL(18,2) | Total sales amount |
| total_customers | INT | Number of customers in the region |
| total_orders | INT | Number of orders placed |
| avg_sales_per_customer | DECIMAL(18,2) | Average sales value per customer |
| year | INT | Year of sales |

---

## 🧩 Relationships (Logical)
| View | Key Joins |
|-------|-------------|
| All views | Join on `customer_id`, `product_code`, `date_id` between fact and dimension tables |

---

## ⚙️ Business Use Cases
- **Power BI Dashboards**
  - Global Sales Overview
  - Product & Profitability Performance
  - Customer Retention & Segmentation
  - Regional Revenue Analysis
- **Ad-hoc SQL Analysis**
  - Quick queries on KPIs like revenue, quantity sold, and customer distribution
- **Reporting Automation**
  - Simplifies data access for analytics and scheduled reports

---

## 📅 Update Frequency
- **Gold Layer Views** are refreshed daily after Silver layer ETL completion.

---

## 🧾 Author & Versioning
| Field | Value |
|--------|--------|
| Author | Mostafa Khaled Farag |
| Date Created | 2025-10-06 |
| Version | 1.0 |
| Contact | [mosta.mk@gmail.com](mailto:mosta.mk@gmail.com) |
