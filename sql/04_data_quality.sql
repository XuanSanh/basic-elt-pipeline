USE ELTPractice;
GO

-- RAW
SELECT 'raw.customers' AS table_name, COUNT(*) AS row_count
FROM raw.customers

UNION ALL

SELECT 'raw.products', COUNT(*)
FROM raw.products

UNION ALL

SELECT 'raw.orders', COUNT(*)
FROM raw.orders

-- STAGING
UNION ALL

SELECT 'staging.customers', COUNT(*)
FROM staging.customers

UNION ALL

SELECT 'staging.products', COUNT(*)
FROM staging.products

UNION ALL

SELECT 'staging.orders', COUNT(*)
FROM staging.orders

-- MART
UNION ALL

SELECT 'mart.fact_sales', COUNT(*)
FROM mart.fact_sales;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END) AS null_customer_name,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END) AS null_product_name,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS null_unit_price,
    SUM(CASE WHEN total_amount IS NULL THEN 1 ELSE 0 END) AS null_total_amount
FROM mart.fact_sales;

SELECT *
FROM mart.fact_sales
WHERE quantity <= 0
   OR unit_price <= 0
   OR total_amount <= 0;

SELECT *
FROM mart.fact_sales
WHERE total_amount <> quantity * unit_price;