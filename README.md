# Basic ELT Pipeline

A small end-to-end ELT (Extract, Load, Transform) pipeline built with **Python, Pandas, PyODBC, and Microsoft SQL Server**.

This project is designed as a practical Data Engineering learning project to understand the basic concepts of:

* ELT Pipeline
* Python data ingestion
* CSV data processing
* SQL Server
* RAW / STAGING / MART data layers
* Full Load
* Incremental Upsert
* Data Transformation
* Data Quality Checks
* Idempotent Pipeline Design
* Git and GitHub

---

## 1. Project Overview

The pipeline takes raw data from CSV files and loads it into SQL Server.

The data then goes through three layers:

```text
CSV Files
   │
   │ Extract
   ▼
Python + Pandas
   │
   │ Load
   ▼
┌─────────────────┐
│   RAW Layer     │
│  Source-like    │
│      Data       │
└────────┬────────┘
         │
         │ Transform
         ▼
┌─────────────────┐
│ STAGING Layer   │
│ Cleaned Data    │
│ Standardized    │
└────────┬────────┘
         │
         │ Transform
         ▼
┌─────────────────┐
│   MART Layer    │
│ Analytics-ready │
│      Data       │
└─────────────────┘
```

The project follows the **ELT** approach:

```text
Extract → Load → Transform
```

Instead of transforming data before loading it into the database, the raw data is first loaded into SQL Server and then transformed using SQL.

---

# 2. ELT vs ETL

## ETL

```text
Extract
   ↓
Transform
   ↓
Load
```

Transformation happens before loading the data into the target database.

## ELT

```text
Extract
   ↓
Load
   ↓
Transform
```

Transformation happens inside the target database.

This project uses ELT because:

* Python extracts data from CSV files.
* Python loads the data into SQL Server RAW tables.
* SQL Server performs data transformation.
* STAGING and MART layers are created using SQL.

---

# 3. Tech Stack

| Technology           | Purpose                              |
| -------------------- | ------------------------------------ |
| Python               | Data ingestion                       |
| Pandas               | Reading and processing CSV files     |
| PyODBC               | Connecting Python to SQL Server      |
| Microsoft SQL Server | Data storage and transformation      |
| SQL                  | Data transformation and data quality |
| PowerShell           | Running Python and Git commands      |
| Git                  | Version control                      |
| GitHub               | Source code repository               |

---

# 4. Project Structure

```text
basic_elt/
│
├── data/
│   ├── customers.csv
│   ├── products.csv
│   └── orders.csv
│
├── src/
│   └── load_raw.py
│
├── sql/
│   ├── 01_create_raw.sql
│   ├── 02_transform_staging.sql
│   ├── 03_transform_mart.sql
│   └── 04_data_quality.sql
│
├── .gitignore
└── README.md
```

---

# 5. Source Data

The pipeline uses three CSV files.

## Customers

```text
customer_id
name
city
```

Example:

```csv
customer_id,name,city
1,Nguyen Van An,HCM
2,Tran Van B,Hanoi
3,Le Van C,Danang
```

---

## Products

```text
product_id
product_name
category
price
```

Example:

```csv
product_id,product_name,category,price
101,Laptop,Electronics,1500
102,Mouse,Accessories,25
103,Keyboard,Accessories,50
```

---

## Orders

```text
order_id
customer_id
product_id
quantity
order_date
```

Example:

```csv
order_id,customer_id,product_id,quantity,order_date
1001,1,101,1,2026-09-01
1002,2,102,2,2026-09-02
1003,1,103,1,2026-09-03
```

The order dataset was also used to test incremental data ingestion by adding new orders and modifying an existing order.

---

# 6. Database

The project uses Microsoft SQL Server.

## Server

```text
Loveyouu\MSSQLSERVER01
```

## Database

```text
ELTPractice
```

The database is divided into three schemas:

```text
raw
staging
mart
```

---

# 7. Data Architecture

## RAW

The RAW layer stores data close to the original source.

```text
raw.customers
raw.products
raw.orders
```

The purpose of RAW is to provide a source-like copy of the incoming data before further transformation.

---

## STAGING

The STAGING layer contains cleaned and standardized data.

```text
staging.customers
staging.products
staging.orders
```

Examples of transformations:

* Trim unnecessary spaces.
* Convert city names to uppercase.
* Convert product categories to uppercase.
* Remove products with invalid prices.
* Remove orders with invalid quantities.

Example:

```sql
LTRIM(RTRIM(name))
```

and:

```sql
UPPER(city)
```

---

## MART

The MART layer contains analytics-ready data.

The main table is:

```text
mart.fact_sales
```

It combines:

* Orders
* Customers
* Products

into a single fact table.

Important columns include:

```text
order_id
order_date
customer_id
customer_name
city
product_id
product_name
category
quantity
unit_price
total_amount
```

The sales amount is calculated as:

```text
total_amount = quantity × unit_price
```

---

# 8. Pipeline Flow

The complete pipeline works as follows:

```text
customers.csv ─────┐
                   │
products.csv ──────┼──> Python + Pandas
                   │
orders.csv ────────┘
                         │
                         ▼
                  SQL Server RAW
                         │
                         ▼
                  SQL Server STAGING
                         │
                         ▼
                  SQL Server MART
                         │
                         ▼
                  Data Quality Checks
```

---

# 9. Step 1 — Extract

Python uses Pandas to read the CSV files.

Example:

```python
customers = pd.read_csv("data/customers.csv")
products = pd.read_csv("data/products.csv")
orders = pd.read_csv("data/orders.csv")
```

At this stage, the data is extracted from the source files but has not yet been transformed into the final analytical format.

---

# 10. Step 2 — Load RAW

Python connects to SQL Server using PyODBC.

Example connection:

```python
connection_string = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    "Trusted_Connection=yes;"
)
```

The extracted data is then loaded into RAW tables.

The RAW layer contains:

```text
raw.customers
raw.products
raw.orders
```

---

# 11. Incremental Upsert

The project also implements a simple incremental loading mechanism for orders.

Instead of deleting and reloading every order, the pipeline checks whether an `order_id` already exists.

The logic is:

```text
                 Order from CSV
                       │
                       ▼
              Does order_id exist?
                 /            \
               No              Yes
               │                │
               ▼                ▼
            INSERT       Compare existing data
                                │
                         ┌──────┴──────┐
                         │             │
                       Same         Changed
                         │             │
                         ▼             ▼
                       SKIP          UPDATE
```

### New order

If the `order_id` does not exist:

```text
INSERT
```

Example:

```text
1008 → Inserted
```

### Existing unchanged order

If the order already exists and its values have not changed:

```text
SKIP
```

Example:

```text
1001 → Skipped unchanged order
```

### Existing changed order

If an existing order has changed:

```text
UPDATE
```

For example, order `1010` was initially loaded with:

```text
quantity = 2
```

and later changed to:

```text
quantity = 5
```

The pipeline detects the difference and updates the RAW record.

---

# 12. Why Incremental Upsert?

The incremental logic demonstrates a basic real-world data engineering concept.

Instead of always doing:

```text
DELETE → INSERT EVERYTHING
```

the pipeline can determine:

```text
New data      → INSERT
Changed data  → UPDATE
Unchanged data → SKIP
```

This project intentionally uses a simple row-by-row implementation for learning purposes.

It is not intended to be a production-scale ingestion framework.

---

# 13. Step 3 — Transform STAGING

The STAGING transformation is implemented in:

```text
sql/02_transform_staging.sql
```

The transformation first clears the existing STAGING data:

```sql
TRUNCATE TABLE staging.orders;
TRUNCATE TABLE staging.products;
TRUNCATE TABLE staging.customers;
```

Then it loads transformed data from RAW.

For customers:

```sql
SELECT
    customer_id,
    LTRIM(RTRIM(name)),
    UPPER(city)
FROM raw.customers;
```

For products:

```sql
SELECT
    product_id,
    LTRIM(RTRIM(product_name)),
    UPPER(category),
    price
FROM raw.products
WHERE price > 0;
```

For orders:

```sql
SELECT
    order_id,
    customer_id,
    product_id,
    quantity,
    order_date
FROM raw.orders
WHERE quantity > 0;
```

---

# 14. Step 4 — Transform MART

The MART transformation is implemented in:

```text
sql/03_transform_mart.sql
```

The pipeline creates the final sales fact table by joining:

```text
staging.orders
        │
        ├──── staging.customers
        │
        └──── staging.products
```

The final data contains customer, product and sales information.

The main calculation is:

```sql
o.quantity * p.price AS total_amount
```

Therefore:

```text
Total Amount = Quantity × Unit Price
```

Example:

```text
Keyboard
Quantity = 2
Unit Price = 50

Total Amount = 2 × 50 = 100
```

---

# 15. Idempotency

The transformation stages are designed to be rerunnable.

STAGING uses:

```sql
TRUNCATE TABLE
```

before inserting transformed data.

MART also uses:

```sql
TRUNCATE TABLE
```

before rebuilding the fact table.

Therefore, running the transformation scripts multiple times does not continuously duplicate the same records.

The order loading stage uses incremental logic:

```text
INSERT new records
UPDATE changed records
SKIP unchanged records
```

This provides a basic demonstration of idempotent pipeline behavior.

---

# 16. Data Quality

Data quality checks are implemented in:

```text
sql/04_data_quality.sql
```

The checks include:

### 1. Row Count Checks

Compare record counts between:

```text
RAW
STAGING
MART
```

This helps detect unexpected missing or extra records.

---

### 2. NULL Checks

The MART table is checked for unexpected NULL values.

Important fields include:

```text
order_id
customer_id
product_id
quantity
unit_price
total_amount
```

---

### 3. Positive Value Checks

The pipeline verifies that:

```text
quantity > 0
unit_price > 0
total_amount > 0
```

---

### 4. Calculation Validation

The pipeline verifies:

```text
total_amount = quantity × unit_price
```

This ensures the calculated sales amount is consistent with the source values.

---

### 5. Duplicate Order Check

The pipeline checks for duplicate:

```text
order_id
```

This helps verify that the order data has not been unintentionally duplicated.

---

# 17. Running the Project

## Prerequisites

Install:

* Python
* Microsoft SQL Server
* ODBC Driver 17 for SQL Server
* Git

Python packages:

```text
pandas
pyodbc
```

---

## Create Virtual Environment

From the project directory:

```powershell
python -m venv .venv
```

Activate it:

```powershell
.venv\Scripts\Activate.ps1
```

Install dependencies:

```powershell
pip install pandas pyodbc
```

---

# 18. Create Database Tables

Open SQL Server Management Studio or another SQL Server client.

Create the database:

```text
ELTPractice
```

Then create the required schemas:

```text
raw
staging
mart
```

Run:

```text
sql/01_create_raw.sql
```

The remaining staging and mart tables should exist according to the project database setup.

---

# 19. Run Python Loader

From the project root:

```powershell
python src/load_raw.py
```

The Python script will:

1. Connect to SQL Server.
2. Read the CSV files.
3. Load customer and product data.
4. Perform incremental upsert for orders.
5. Insert new orders.
6. Update changed orders.
7. Skip unchanged orders.
8. Close the SQL Server connection.

Example output:

```text
Connected to SQL Server successfully!
CSV files loaded successfully!

Skipped unchanged order: 1001
Skipped unchanged order: 1002
Inserted order: 1008
Inserted order: 1009
Updated order: 1010

Incremental upsert completed!
Pipeline finished!
```

---

# 20. Run STAGING Transformation

Run:

```text
sql/02_transform_staging.sql
```

This transforms:

```text
RAW → STAGING
```

---

# 21. Run MART Transformation

Run:

```text
sql/03_transform_mart.sql
```

This transforms:

```text
STAGING → MART
```

---

# 22. Run Data Quality Checks

Finally, run:

```text
sql/04_data_quality.sql
```

This validates the resulting dataset.

---

# 23. Example Dataset

The project initially contains:

```text
5 customers
5 products
7 orders
```

Additional incremental orders were then added:

```text
1008
1009
1010
```

The pipeline was tested with:

```text
INSERT
UPDATE
SKIP
```

operations.

For example:

```text
1008 → INSERT
1009 → INSERT
1010 → INSERT
1010 → UPDATE
```

After the update, order `1010` has:

```text
quantity = 5
```

---

# 24. Full Pipeline Execution

The complete execution order is:

```text
1. Prepare CSV files
        ↓
2. Run Python loader
        ↓
3. RAW tables updated
        ↓
4. Run 02_transform_staging.sql
        ↓
5. STAGING tables rebuilt
        ↓
6. Run 03_transform_mart.sql
        ↓
7. MART table rebuilt
        ↓
8. Run 04_data_quality.sql
        ↓
9. Validate pipeline
```

---

# 25. Important Concepts Demonstrated

This project demonstrates the following Data Engineering concepts:

### Data Ingestion

Reading source data from CSV files using Python and Pandas.

### Database Connectivity

Connecting Python to SQL Server using PyODBC.

### ELT

Loading raw data into the database before performing transformations.

### Data Layering

Using:

```text
RAW
STAGING
MART
```

to separate different stages of data processing.

### Data Transformation

Cleaning and standardizing data with SQL.

### Fact Table

Creating:

```text
mart.fact_sales
```

for analytical purposes.

### Incremental Loading

Detecting:

```text
New records
Changed records
Unchanged records
```

### Upsert

Using:

```text
INSERT
UPDATE
SKIP
```

based on existing records.

### Idempotency

Allowing transformation scripts to be safely rerun without continuously creating duplicate records.

### Data Quality

Checking:

```text
Row counts
NULL values
Positive values
Calculations
Duplicates
```

---

# 26. Project Limitations

This is a small learning project and is intentionally kept simple.

It does not currently include:

* Apache Airflow
* Apache Spark
* Databricks
* Microsoft Fabric
* Cloud storage
* Cloud data warehouse
* Streaming data
* Distributed processing
* Automated scheduling
* Production monitoring
* Advanced logging
* Batch optimization
* Large-scale parallel processing

The incremental order loading is implemented using a simple row-by-row approach.

For a production system, the pipeline could be improved with batch processing, orchestration, monitoring, better error handling, transaction management, and scalable storage/compute solutions.

---

# 27. Learning Objectives

The main objective of this project is to build a practical understanding of a basic Data Engineering pipeline.

After completing this project, the key workflow is:

```text
Source Data
    ↓
Python
    ↓
SQL Server RAW
    ↓
SQL Transformation
    ↓
STAGING
    ↓
SQL Transformation
    ↓
MART
    ↓
Data Quality
```

This provides a foundation for learning more advanced technologies such as:

```text
Airflow
PySpark
Microsoft Fabric
Azure
AWS
GCP
Data Warehouses
Data Lakes
```

---

# 28. Git Workflow

The project is version-controlled with Git.

Initialize repository:

```powershell
git init
```

Check status:

```powershell
git status
```

Add files:

```powershell
git add .
```

Create commit:

```powershell
git commit -m "Add basic ELT pipeline"
```

Connect GitHub repository:

```powershell
git remote add origin https://github.com/xuansanh/basic-elt-pipeline.git
```

Push:

```powershell
git push -u origin main
```

---

# 29. Repository

GitHub repository:

**basic-elt-pipeline**

```text
https://github.com/xuansanh/basic-elt-pipeline
```

---

# 30. Final Result

The project implements a complete small-scale ELT pipeline:

```text
             CSV
              │
              ▼
       Python + Pandas
              │
              ▼
       ┌──────────────┐
       │     RAW      │
       │              │
       │ customers    │
       │ products     │
       │ orders       │
       └──────┬───────┘
              │
              ▼
       ┌──────────────┐
       │   STAGING    │
       │              │
       │ Clean        │
       │ Standardize  │
       │ Validate     │
       └──────┬───────┘
              │
              ▼
       ┌──────────────┐
       │     MART     │
       │              │
       │  fact_sales  │
       └──────┬───────┘
              │
              ▼
       Data Quality
          Checks
```

The project demonstrates the fundamental workflow of a Data Engineering pipeline from **source data ingestion to analytics-ready data**.
