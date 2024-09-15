-- Brazilian-E-Commerce-Analysis 
-- 1. Order Analysis  // Q1 : How do order counts vary by order status on a monthly basis?

SELECT  
    TO_CHAR(DATE_TRUNC('month', order_approved_at), 'YYYY-MM') AS order_month,
    COUNT(DISTINCT order_id) AS order_count
FROM 
    orders
WHERE 
    order_approved_at IS NOT NULL
GROUP BY 
    1
ORDER BY 
    1;
	
-- Q2 :  Which categories are most popular on Nossa Senhora da Assunção Day?  

SELECT 
        DATE_TRUNC('month', order_approved_at)::date AS order_month,
	order_status,
    COUNT(order_id) AS order_count
FROM 
    orders 
	WHERE order_approved_at IS NOT NULL
GROUP BY 
   1,2
ORDER BY 
    1,2;

-- Q3 :  Which categories are most popular on Nossa Senhora da Assunção Day? (15 AUGUST)

WITH a AS (
		SELECT
		TO_CHAR(o.order_purchase_timestamp, 'YYYY.MM') AS order_date,
		p.product_category_name AS product_category,
	  COUNT (DISTINCT oi.order_id) AS order_number
	FROM
		orders o
	JOIN
		order_items oi ON o.order_id = oi.order_id
	JOIN
		products p ON oi.product_id = p.product_id
	WHERE
		 o.order_purchase_timestamp BETWEEN '2017-07-14' AND '2017-08-14'
	GROUP BY
		order_date, product_category
	ORDER BY
		 order_number DESC
		 LIMIT 7

	),
	b AS (
	   SELECT
		TO_CHAR(o.order_purchase_timestamp, 'YYYY.MM') AS order_date,
		p.product_category_name AS product_category,
		COUNT(oi.order_id) AS order_number
	FROM
		orders o
	JOIN
		order_items oi ON o.order_id = oi.order_id
	JOIN
		products p ON oi.product_id = p.product_id
	WHERE
		 o.order_purchase_timestamp BETWEEN '2018-07-14' AND '2018-08-14'
		GROUP BY
		order_date, product_category
	ORDER BY
		 order_number DESC
		 LIMIT 7

	)
	SELECT
		  order_date,
		 product_category,
		order_number
	FROM
	   a
	UNION ALL
	SELECT
		order_date,
		 product_category,
		order_number
	FROM
		b
	ORDER BY 1,3 DESC;	

-- Q4 : How do order counts vary by days of the week and days of the month?


--Days of the Week
	
SELECT
    CASE EXTRACT(DOW FROM order_purchase_timestamp)
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
        WHEN 0 THEN 'Sunday'
    END AS days_of_the_week,
    COUNT(order_id) AS order_count
FROM
    orders
GROUP BY
    days_of_the_week
ORDER BY
    order_count DESC;


--Days of the Month

SELECT
    EXTRACT(DAY FROM order_purchase_timestamp) AS days_of_the_month,
    COUNT(order_id) AS order_count
FROM
    orders
WHERE
    order_purchase_timestamp BETWEEN '2016-01-01' AND '2018-12-31' 
GROUP BY
    days_of_the_month
ORDER BY
    days_of_the_month ASC;	


-- 2. Customer Analysis  // Q1 : In which cities do customers shop more?

WITH table1 AS(
	SELECT customer_unique_id, 
customer_city, 
COUNT (customer_city) AS order_place
FROM customers
GROUP BY 1,2
), table2 AS (
SELECT customer_unique_id,
customer_city,
order_place,
ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY order_place DESC) AS rn
FROM table1
	), table3 AS(
		SELECT customer_unique_id,
SUM(order_place) AS total_order
FROM table2 
GROUP BY 1
ORDER BY 1
), table4 AS(
	SELECT t2.customer_unique_id,
customer_city, 
total_order
FROM table2 t2
JOIN table3 t3 ON t2.customer_unique_id= t3.customer_unique_id
WHERE rn=1
) SELECT 
    customer_city,
    SUM(total_order) AS total_orders
FROM 
    table4
GROUP BY 
    customer_city
ORDER BY 
    total_orders DESC;

-- 3. Seller Analysis // Q1 : Which vendors deliver orders to customers the fastest?

WITH delivery_times AS (
    SELECT
        oi.seller_id,
        ROUND(AVG(EXTRACT(EPOCH FROM o.order_delivered_carrier_date - o.order_approved_at) / 3600)) AS avg_delivery_time,
        COUNT(oi.order_item_id) AS total_orders
    FROM
        orders o
    INNER JOIN
        order_items oi ON o.order_id = oi.order_id
    WHERE
        o.order_status = 'delivered'
    GROUP BY
        oi.seller_id
),
review_scores AS (
    SELECT
        oi.seller_id,
        ROUND(AVG(r.review_score), 2) AS review_score
    FROM
        orders o
    INNER JOIN
        order_items oi ON o.order_id = oi.order_id
    INNER JOIN
        reviews r ON o.order_id = r.order_id
    WHERE
        o.order_status = 'delivered'
    GROUP BY
        oi.seller_id
)
SELECT
    dt.seller_id,
    dt.avg_delivery_time || ' hrs' AS delivery_time,
    dt.total_orders,
    rs.review_score
FROM
    delivery_times dt
LEFT JOIN
    review_scores rs ON dt.seller_id = rs.seller_id
WHERE
    dt.total_orders > 100
ORDER BY
    dt.avg_delivery_time ASC
LIMIT 5;

-- Q2 : Which sellers sell products from more categories?

SELECT
    oi.seller_id,
    COUNT(DISTINCT p.product_category_name) AS category_count,
    COUNT(DISTINCT o.order_id) AS total_sales
FROM
    order_items oi
JOIN
    products p ON oi.product_id = p.product_id
JOIN
    orders o ON oi.order_id = o.order_id
GROUP BY
    oi.seller_id
ORDER BY 2 DESC --ORDER BY 3 DESC
LIMIT 10; 

-- 4. Payment Analysis  // Q1 : In which region do users with a high number of installments when making payments live the most?

WITH tablo1 AS (
SELECT   c.customer_unique_id, c.customer_state, 
       ROUND(AVG(p.payment_installments),0) AS total_installments
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN payments p ON o.order_id = p.order_id
WHERE
payment_installments >= 6
GROUP BY 1,2
ORDER BY 3 DESC
)
SELECT 
    customer_state, 
    total_installments, 
    COUNT(customer_unique_id) AS customer_count
FROM 
    Tablo1
GROUP BY 
    customer_state, total_installments
ORDER BY 
     3 DESC;

--Q2: Which categories have the highest use of installment payments?

--Single Payment

SELECT pay.payment_installments,
    p.product_category_name,
    COUNT(o.order_id) AS order_count
FROM
    orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN payments pay ON o.order_id = pay.order_id
WHERE
    pay.payment_installments = 1
GROUP BY
   1, p.product_category_name
ORDER BY
    3 DESC;

--Installments

SELECT pay.payment_installments,
    p.product_category_name,
    COUNT(o.order_id) AS order_count
FROM
    orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN payments pay ON o.order_id = pay.order_id
WHERE
    pay.payment_installments > 1
GROUP BY
    1,2
ORDER BY
    3 DESC;




