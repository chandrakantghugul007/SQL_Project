-- SQL SuperStore Product SALES Data Project With Four Table --

create database project_db;
use project_db;

-- Describe All Tables --
describe customers;     select * from customers;
describe order_items;   select * from order_items;
describe orders;        select * from orders;
describe products;      select * from products;

-- DDL (Data Definition Language)
-- CREATE TABBLE
-- ALTER TABLE ... ADD CONSTRAINT / MODIFY
-- DROP TABLE
 

-- Assign the Primary Key --
ALTER TABLE customers   ADD CONSTRAINT pk_customers   PRIMARY KEY (customer_id);
ALTER TABLE products    ADD CONSTRAINT pk_products    PRIMARY KEY (product_id);
ALTER TABLE orders      ADD CONSTRAINT pk_orders      PRIMARY KEY (order_id);
ALTER TABLE order_items ADD CONSTRAINT pk_order_items PRIMARY KEY (order_item_id);

  -- Assign Foreign Keys in tables --
  ALTER TABLE orders
  ADD CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE order_items
  ADD CONSTRAINT fk_items_order   FOREIGN KEY (order_id)   REFERENCES orders(order_id),
  ADD CONSTRAINT fk_items_product FOREIGN KEY (product_id) REFERENCES products(product_id);
  

-- Modifying the Tables --
ALTER TABLE customers
  MODIFY first_name  VARCHAR(50)  NOT NULL,
  MODIFY last_name   VARCHAR(50)  NOT NULL,
  MODIFY email       VARCHAR(100) NOT NULL,
  MODIFY signup_date DATE         NOT NULL;

ALTER TABLE products
  MODIFY product_name VARCHAR(100)  NOT NULL,
  MODIFY category     VARCHAR(50)   NOT NULL,
  MODIFY unit_cost    DECIMAL(10,2) NOT NULL,
  MODIFY unit_price   DECIMAL(10,2) NOT NULL;

ALTER TABLE orders
  MODIFY customer_id   INT         NOT NULL,
  MODIFY order_date    DATE        NOT NULL,
  MODIFY sales_channel VARCHAR(30) NOT NULL,
  MODIFY order_status  VARCHAR(20) NOT NULL;

ALTER TABLE order_items
  MODIFY order_id     INT           NOT NULL,
  MODIFY product_id   INT           NOT NULL,
  MODIFY quantity     INT           NOT NULL,
  MODIFY unit_price   DECIMAL(10,2) NOT NULL,
  MODIFY discount_pct DECIMAL(4,2)  NOT NULL DEFAULT 0,
  MODIFY line_total   DECIMAL(12,2) NOT NULL;
  
  -- Assign Unique --
ALTER TABLE customers ADD CONSTRAINT uq_customers_email UNIQUE (email);
ALTER TABLE products  ADD CONSTRAINT uq_products_name   UNIQUE (product_name);


-- Check Constraints -- 
ALTER TABLE customers
  ADD CONSTRAINT chk_customers_segment CHECK (segment IN ('Consumer','Corporate','Home Office'));

ALTER TABLE products
  ADD CONSTRAINT chk_products_cost  CHECK (unit_cost >= 0),
  ADD CONSTRAINT chk_products_price CHECK (unit_price >= unit_cost);

ALTER TABLE orders
  ADD CONSTRAINT chk_orders_channel CHECK (sales_channel IN ('Online','In-Store','Phone','Marketplace')),
  ADD CONSTRAINT chk_orders_status  CHECK (order_status IN ('Delivered','Shipped','Processing','Cancelled','Returned'));

ALTER TABLE order_items
  ADD CONSTRAINT chk_items_qty      CHECK (quantity > 0),
  ADD CONSTRAINT chk_items_discount CHECK (discount_pct BETWEEN 0 AND 1);
  

-- DML (Data Manipulation Language)--
-- INSERT INTO
-- SELECT
-- LIMIT
-- JOINS
-- UPDATE


-- SELECT with LIMIT --
SELECT customer_id, first_name, last_name, city, segment
FROM customers
LIMIT 10;

SELECT product_id, product_name, category, unit_price
FROM products
WHERE category = 'Electronics'
LIMIT 10;

SELECT order_id, customer_id, order_date, sales_channel, order_status
FROM orders
WHERE order_status = 'Delivered'
LIMIT 10;

SELECT order_item_id, order_id, product_id, quantity, discount_pct, line_total
FROM order_items
WHERE quantity >= 5
LIMIT 10;

-- JOIN
-- Customers + Orders
-- Customer Name with its order
SELECT c.first_name, c.last_name, o.order_id, o.order_date, o.order_status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id          -- where order_status = 'Delivered'     -- order by order_date
LIMIT 10;

-- orders + order_items
-- orders line items (quantity of product order)
SELECT o.order_id, o.order_status, oi.order_item_id, oi.quantity, oi.line_total
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
LIMIT 10;

-- order_items + products
-- Name and Category of Product
SELECT oi.order_item_id,p.product_name, p.category, oi.quantity, oi.line_total
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id 
LIMIT 10;

-- JOIN all 4 Tables
-- which customer buy which product and what price and on which date?
SELECT c.first_name, c.last_name, o.order_date, o.sales_channel,
       p.category, p.product_name, oi.quantity, oi.line_total
FROM customers c
JOIN orders o       ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
LIMIT 10;


-- Assign line_Total a ValueCategory
SELECT order_item_id,
       product_id,
       line_total,
       CASE
           WHEN line_total >= 50000 THEN 'High Value'
           WHEN line_total >= 20000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS ValueCategory
FROM order_items;

-- Rank the Customers according there total spend
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       ROUND(SUM(oi.line_total), 2) AS total_spent,
       RANK() OVER (ORDER BY SUM(oi.line_total) DESC) AS spend_rank
FROM customers c
JOIN orders o       ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY spend_rank
LIMIT 10; 


-- What is total amount spent on each product there average discount percent,line count,max_line,min_line?
SELECT p.product_id,
       p.product_name,
       ROUND(SUM(oi.line_total), 2)       AS total_line_amount,
       ROUND(AVG(oi.discount_pct) * 100, 2) AS avg_discount_pct,
       COUNT(oi.order_item_id)            AS line_count,
       MAX(oi.line_total)                 AS max_line,
       MIN(oi.line_total)                 AS min_line
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name
HAVING SUM(oi.line_total) > 100000
ORDER BY total_line_amount desc;

-- Category wise total_line amount,average discount percent,line count,max and min line? --
SELECT p.category,
       ROUND(SUM(oi.line_total), 2)         AS total_line_amount,
       ROUND(AVG(oi.discount_pct) * 100, 2) AS avg_discount_pct,
       COUNT(oi.order_item_id)              AS line_count,
       MAX(oi.line_total)                 AS max_line,
       MIN(oi.line_total)                 AS min_line
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
HAVING SUM(oi.line_total) > 1000000
ORDER BY total_line_amount DESC;

-- Delivery group wise count?
select order_status,Count(*) as order_count from orders
group by order_status;

SELECT CASE
           WHEN order_status = 'Delivered' THEN 'Delivered'
           WHEN order_status IN ('Processing', 'Shipped') THEN 'Pending'
           ELSE 'Others'
       END AS delivery_group,
       COUNT(*) AS order_count
FROM orders
GROUP BY delivery_group;

-- City wise Total Line Amount and Total orders?
SELECT c.city,
       ROUND(SUM(oi.line_total), 2)   AS total_line_amount,
       COUNT(DISTINCT o.order_id)     AS total_orders
FROM customers c
JOIN orders o       ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.city
ORDER BY total_line_amount DESC;

-- Customer wise previous and next order date?
SELECT c.first_name,
       c.last_name,
       o.customer_id,
       o.order_id,
       o.order_date,
       LAG(o.order_date)  OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS previous_order_date,
       LEAD(o.order_date) OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS next_order_date
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.customer_id, o.order_date
LIMIT 20;

-- Top 10 Total orders by customers --
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_orders DESC
limit 10;

-- Products Priced Above the Overall Average Unit Price?
SELECT AVG(unit_price)
FROM products;

SELECT product_id, product_name, category, unit_price
FROM products
WHERE unit_price > (
    SELECT AVG(unit_price)
    FROM products
)
order by unit_price;




-- The analysis shows which products and categories earn the most, which customers spend the most and how order status is spread across deliveries. --