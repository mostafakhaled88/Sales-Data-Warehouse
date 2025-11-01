# 🗂️ Data Catalog – Gold Layer (Sales Data Warehouse)

This document serves as the **data catalog** for the Gold Layer of the Sales Data Warehouse.  
It describes the available **views**, their purpose, columns, and key information to help analysts and business users discover and understand the data.

---

## 1. `vw_sales_performance`

**Purpose:**  
Provides a unified view of all sales transactions enriched with customer, product, and date attributes — used for dashboards and general sales analysis.

| Column Name      | Data Type | Description |
|------------------|-----------|--------------|
| order_number     | NVARCHAR  | Unique sales order identifier |
| status           | NVARCHAR  | Order status (e.g., Shipped, Cancelled) |
| quantity_ordered | INT       | Quantity of items ordered |
| price_each       | MONEY     | Unit price of the product |
| sales_amount     | MONEY     | Total sales value (`quantity_ordered * price_each`) |
| deal_size        | NVARCHAR  | Deal size category (Small / Medium / Large) |
| full_date        | DATE      | Order date |
| year_number      | INT       | Year of the order |
| month_number     | INT       | Month number (1–12) |
| month_name       | NVARCHAR  | Name of the month (e.g., January) |
| quarter_name     | NVARCHAR  | Quarter of the year (e.g., Q1, Q2) |
| customer_name    | NVARCHAR  | Customer full name |
| country          | NVARCHAR  | Country of the customer |
| territory        | NVARCHAR  | Business region (e.g., EMEA, NA, APAC) |
| product_code     | NVARCHAR  | Unique product code |
| product_line     | NVARCHAR  | Product line/category |

**Source:** `silver.fact_sales`, `silver.dim_date`, `silver.dim_customer`, `silver.dim_product`  
**Update Frequency:** Daily  
**Owner:** Sales Analytics Team  

---

## 2. `vw_sales_summary`

**Purpose:**  
Provides aggregated monthly sales metrics per product line for trend analysis.

| Column Name    | Data Type | Description |
|----------------|-----------|-------------|
| year_number     | INT       | Calendar year of the sale |
| month_number    | INT       | Calendar month (1–12) |
| product_line    | NVARCHAR  | Product line/category |
| total_quantity  | INT       | Total quantity sold |
| total_sales     | MONEY     | Total sales amount (USD) |
| avg_unit_price  | MONEY     | Average unit price |

**Source:** `silver.fact_sales`, `silver.dim_product`, `silver.dim_date`  
**Update Frequency:** Daily  
**Owner:** Sales Analytics Team  

---

## 3. `vw_customer_insights`

**Purpose:**  
Provides customer-level KPIs for segmentation and loyalty analysis.

| Column Name           | Data Type | Description |
|-----------------------|-----------|--------------|
| customer_id           | INT       | Unique customer identifier |
| customer_name         | NVARCHAR  | Full customer name |
| country               | NVARCHAR  | Customer’s country |
| territory             | NVARCHAR  | Customer region/territory |
| total_orders          | INT       | Number of orders made |
| total_spent           | MONEY     | Total amount spent |
| total_items_purchased | INT       | Total quantity of items purchased |
| avg_price_per_item    | MONEY     | Average price per item purchased |

**Source:** `silver.fact_sales`, `silver.dim_customer`  
**Update Frequency:** Daily  
**Owner:** Sales Analytics Team  

---

## 4. `vw_regional_performance`

**Purpose:**  
Provides regional performance KPIs by country and month for executive dashboards.

| Column Name     | Data Type | Description |
|-----------------|-----------|--------------|
| country         | NVARCHAR  | Customer country |
| territory       | NVARCHAR  | Business region (NA, EMEA, APAC, Other) |
| year_number     | INT       | Calendar year |
| month_number    | INT       | Calendar month (1–12) |
| total_sales     | MONEY     | Total sales amount (USD) |
| total_quantity  | INT       | Total quantity sold |
| active_customers| INT       | Count of distinct customers placing orders |

**Source:** `silver.fact_sales`, `silver.dim_customer`, `silver.dim_date`  
**Update Frequency:** Daily  
**Owner:** Sales Analytics Team  

---

## Notes

- All monetary fields are reported in **USD**.  
- Gold Layer views are **read-only** and optimized for reporting and dashboards.  
- The Gold Layer is refreshed **daily** after successful Silver Layer ETL completion.  
- For questions, corrections, or new metric requests, contact the **Sales Analytics Team**.

---

| Contact | [mosta.mk@gmail.com](mailto:mosta.mk@gmail.com) |

---

