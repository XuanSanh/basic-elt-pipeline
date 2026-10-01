USE ELTPractice;
GO

CREATE TABLE raw.customers (
    customer_id INT,
    name VARCHAR(100),
    city VARCHAR(100)
);
GO

CREATE TABLE raw.products (
    product_id INT,
    product_name VARCHAR(100),
    category VARCHAR(100),
    price DECIMAL(10,2)
);
GO

CREATE TABLE raw.orders (
    order_id INT,
    customer_id INT,
    product_id INT,
    quantity INT,
    order_date DATE
);
GO

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'raw';