USE ELTPractice;
GO

TRUNCATE TABLE mart.fact_sales;
GO

CREATE TABLE mart.fact_sales (
    order_id INT,
    order_date DATE,
    customer_id INT,
    customer_name VARCHAR(100),
    city VARCHAR(100),
    product_id INT,
    product_name VARCHAR(100),
    category VARCHAR(100),
    quantity INT,
    unit_price DECIMAL(10,2),
    total_amount DECIMAL(12,2)
);
GO

INSERT INTO mart.fact_sales
(
    order_id,
    order_date,
    customer_id,
    customer_name,
    city,
    product_id,
    product_name,
    category,
    quantity,
    unit_price,
    total_amount
)
SELECT
    o.order_id,
    o.order_date,
    c.customer_id,
    c.customer_name,
    c.city,
    p.product_id,
    p.product_name,
    p.category,
    o.quantity,
    p.price,
    o.quantity * p.price AS total_amount
FROM staging.orders o
JOIN staging.customers c
    ON o.customer_id = c.customer_id
JOIN staging.products p
    ON o.product_id = p.product_id;
GO