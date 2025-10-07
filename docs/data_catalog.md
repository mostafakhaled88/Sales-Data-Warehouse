# 🗂️ Data Catalog – Gold Layer (Sales Data Warehouse)



This document serves as the **data catalog** for the Gold Layer of the Sales Data Warehouse. It describes the available **views**, their purpose, columns, and key information to help analysts and business users discover and understand the data.

---

## 1. `vw_sales_summary`

**Purpose:** Provides aggregated monthly sales metrics per product.

| Column Name       | Data Type | Description                                  |
|------------------|-----------|----------------------------------------------|
| year              | INT       | Calendar year of the sale                     |
| month             | INT       | Calendar month of the sale (1–12)           |
| product_line      | NVARCHAR  | Product line/category                        |
| product_code      | NVARCHAR  | Unique product code                           |
| total_quantity    | INT       | Total quantity sold                           |
| total_sales       | MONEY     | Total sales amount (USD)                      |
| avg_unit_price    | MONEY     | Average unit price                            |

**Source:** `silver.fact_sales`, `silver.dim_product`, `silver.dim_date`  
**Update Frequency:** Daily  
**Owner:** Sales Analytics Team

---

## 2. `vw_product_performance`

**Purpose:** Provides product-level performance KPIs.

| Column Name        | Data Type | Description                                  |
|-------------------|-----------|----------------------------------------------|
| product_line       | NVARCHAR  | Product line/category                        |
| product_code       | NVARCHAR  | Unique product code                           |
| msrp               | MONEY     | Manufacturer's Suggested Retail Price        |
| total_revenue      | MONEY     | Total revenue generated                       |
| total_units_sold   | INT       | Total units sold                              |
| avg_selling_price  | MONEY     | Average selling price per unit                |
| revenue_per_unit   | MONEY     | Revenue per unit sold (total_revenue / total_units_sold) |

**Source:** `silver.fact_sales`, `silver.dim_product`  
**Update Frequency:** Daily  
**Owner:** Sales Analytics Team

---

## 3. `vw_customer_insights`

**Purpose:** Provides customer-level metrics for analytics and segmentation.

| Column Name           | Data Type | Description                                    |
|-----------------------|-----------|-----------------------------------------------|
| customer_id           | INT       | Unique customer identifier                     |
| customer_name         | NVARCHAR  | Full customer name                             |
| country               | NVARCHAR  | Customer country                               |
| territory             | NVARCHAR  | Customer region/territory (NA, EMEA, APAC, Other) |
| total_orders          | INT       | Total number of orders by customer            |
| total_spent           | MONEY     | Total amount spent by customer                |
| total_items_purchased | INT       | Total quantity of items purchased             |
| avg_price_per_item    | MONEY     | Average price per item purchased              |

**Source:** `silver.fact_sales`, `silver.dim_customer`  
**Update Frequency:** Daily  
**Owner:** Sales Analytics Team

---

## 4. `vw_regional_performance`

**Purpose:** Provides regional/territory-level KPIs by month for reporting and dashboards.

| Column Name       | Data Type | Description                                |
|------------------|-----------|--------------------------------------------|
| country           | NVARCHAR  | Country of the customer                     |
| territory         | NVARCHAR  | Region/territory (NA, EMEA, APAC, Other)  |
| year              | INT       | Calendar year of the sales                  |
| month             | INT       | Calendar month of the sales                 |
| total_sales       | MONEY     | Total sales amount (USD)                    |
| total_quantity    | INT       | Total quantity sold                          |
| active_customers  | INT       | Count of distinct active customers          |

**Source:** `silver.fact_sales`, `silver.dim_customer`, `silver.dim_date`  
**Update Frequency:** Daily  
**Owner:** Sales Analytics Team

---

## Notes

- All monetary columns are in **USD**.  
- Views are **read-only** and designed for reporting, dashboarding, and business analytics.  
- The **Gold Layer** is refreshed daily from the **Silver Layer**, which is cleaned and conformed data from the Bronze Layer.  
- Contact the **Sales Analytics Team** for any questions regarding metrics or definitions.

---

| Contact | [mosta.mk@gmail.com](mailto:mosta.mk@gmail.com) |
