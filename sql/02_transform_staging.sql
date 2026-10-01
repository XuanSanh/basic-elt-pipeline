USE ELTPractice;
GO

-- Clear old staging data
TRUNCATE TABLE staging.orders;
TRUNCATE TABLE staging.products;
TRUNCATE TABLE staging.customers;
GO

CREATE TABLE staging.customers (
    customer_id INT,
    customer_name VARCHAR(100),
    city VARCHAR(100)
);
GO

INSERT INTO staging.customers
(
    customer_id,
    customer_name,
    city
)
SELECT
    customer_id,
    LTRIM(RTRIM(name)),
    UPPER(city)
FROM raw.customers;

CREATE TABLE staging.products (
    product_id INT,
    product_name VARCHAR(100),
    category VARCHAR(100),
    price DECIMAL(10,2)
);
GO

INSERT INTO staging.products
(
    product_id,
    product_name,
    category,
    price
)
SELECT
    product_id,
    LTRIM(RTRIM(product_name)),
    UPPER(category),
    price
FROM raw.products
WHERE price > 0;

CREATE TABLE staging.orders (
    order_id INT,
    customer_id INT,
    product_id INT,
    quantity INT,
    order_date DATE
);
GO

INSERT INTO staging.orders
(
    order_id,
    customer_id,
    product_id,
    quantity,
    order_date
)
SELECT
    order_id,
    customer_id,
    product_id,
    quantity,
    order_date
FROM raw.orders
WHERE quantity > 0;