import pandas as pd
import pyodbc


# =========================
# 1. DATABASE CONFIG
# =========================

SERVER = r"Loveyouu\MSSQLSERVER01"
DATABASE = "ELTPractice"

connection_string = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    "Trusted_Connection=yes;"
)


# =========================
# 2. CONNECT TO SQL SERVER
# =========================

conn = pyodbc.connect(connection_string)

print("Connected to SQL Server successfully!")

# =========================
# 3. EXTRACT
# =========================

customers = pd.read_csv("data/customers.csv")
products = pd.read_csv("data/products.csv")
orders = pd.read_csv("data/orders.csv")

print("CSV files loaded successfully!")

# =========================
# 3.1. TRUNCATE TABLES
# =========================
def truncate_raw_tables():

    cursor = conn.cursor()

    cursor.execute("TRUNCATE TABLE raw.orders")
    cursor.execute("TRUNCATE TABLE raw.products")
    cursor.execute("TRUNCATE TABLE raw.customers")

    conn.commit()

    cursor.close()

    print("RAW tables cleared!")
# =========================
# 4. LOAD CUSTOMERS
# =========================

def load_customers(df):

    cursor = conn.cursor()

    for _, row in df.iterrows():

        cursor.execute(
            """
            INSERT INTO raw.customers
            (
                customer_id,
                name,
                city
            )
            VALUES (?, ?, ?)
            """,
            int(row["customer_id"]),
            row["name"],
            row["city"]
        )

    conn.commit()

    cursor.close()

    print("Customers loaded successfully!")
    
def load_products(df):

    cursor = conn.cursor()

    for _, row in df.iterrows():

        cursor.execute(
            """
            INSERT INTO raw.products
            (
                product_id,
                product_name,
                category,
                price
            )
            VALUES (?, ?, ?, ?)
            """,
            int(row["product_id"]),
            row["product_name"],
            row["category"],
            float(row["price"])
        )

    conn.commit()

    cursor.close()

    print("Products loaded successfully!")
    
# def load_orders(df):

#     cursor = conn.cursor()

#     for _, row in df.iterrows():

#         cursor.execute(
#             """
#             INSERT INTO raw.orders
#             (
#                 order_id,
#                 customer_id,
#                 product_id,
#                 quantity,
#                 order_date
#             )
#             VALUES (?, ?, ?, ?, ?)
#             """,
#             int(row["order_id"]),
#             int(row["customer_id"]),
#             int(row["product_id"]),
#             int(row["quantity"]),
#             row["order_date"]
#         )

#     conn.commit()

#     cursor.close()

#     print("Orders loaded successfully!")

def load_orders_incremental(df):
    cursor = conn.cursor()

    for _, row in df.iterrows():
        order_id = int(row["order_id"])

        cursor.execute(
            """
            SELECT
                customer_id,
                product_id,
                quantity,
                order_date
            FROM raw.orders
            WHERE order_id = ?
            """,
            order_id
        )

        existing = cursor.fetchone()

        if existing is None:
            cursor.execute(
                """
                INSERT INTO raw.orders
                (
                    order_id,
                    customer_id,
                    product_id,
                    quantity,
                    order_date
                )
                VALUES (?, ?, ?, ?, ?)
                """,
                order_id,
                int(row["customer_id"]),
                int(row["product_id"]),
                int(row["quantity"]),
                row["order_date"]
            )

            print(f"Inserted order: {order_id}")

        else:
            old_customer_id = existing[0]
            old_product_id = existing[1]
            old_quantity = existing[2]
            old_order_date = existing[3]

            new_customer_id = int(row["customer_id"])
            new_product_id = int(row["product_id"])
            new_quantity = int(row["quantity"])
            new_order_date = row["order_date"]

            if (
                old_customer_id != new_customer_id
                or old_product_id != new_product_id
                or old_quantity != new_quantity
                or str(old_order_date) != str(new_order_date)
            ):
                cursor.execute(
                    """
                    UPDATE raw.orders
                    SET
                        customer_id = ?,
                        product_id = ?,
                        quantity = ?,
                        order_date = ?
                    WHERE order_id = ?
                    """,
                    new_customer_id,
                    new_product_id,
                    new_quantity,
                    new_order_date,
                    order_id
                )

                print(f"Updated order: {order_id}")

            else:
                print(f"Skipped unchanged order: {order_id}")

    conn.commit()
    cursor.close()

    print("Incremental upsert completed!")

# =========================
# 5. RUN
# =========================
# truncate_raw_tables()
# load_customers(customers)
# load_products(products)
# load_orders(orders)

load_orders_incremental(orders)

conn.close()

print("Pipeline finished!")