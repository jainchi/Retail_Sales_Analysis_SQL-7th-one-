CREATE TABLE city(city_id varchar(15) PRIMARY KEY,
city_name VARCHAR(50),
population BIGINT,
estimated_rent FLOAT,
city_rank VARCHAR(25))

CREATE TABLE customers(customer_id INTEGER PRIMARY KEY,
customer_name VARCHAR(95),
city_id VARCHAR(15) REFERENCES city(city_id)
)

CREATE TABLE products
	(product_id BIGINT PRIMARY KEY,
	 product_name VARCHAR(150),
	price INT)

CREATE TABLE sales(
	sale_id	VARCHAR(25) PRIMARY KEY,
	sale_date	date,
	product_id	BIGINT REFERENCES  products (product_id),
	customer_id	INTEGER REFERENCES customers(customer_id),
	total FLOAT,
	rating INTEGER)

select * from city
select * from customers
select * from products
select * from sales

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?


SELECT 
	city_name,
	ROUND(
	(population * 0.25)/1000000, 
	2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC
,3 ASC

----EXTRA QUESTION Write a SQL query to find the number of customers in each city who have made at least one purchase, 
--and return the results sorted by the number of customers in descending order.

SELECT c.city_id,c.city_name, count(cr.customer_id) from  city c
LEFT join customers cr
on cr.city_id = c.city_id 
JOIN sales s
ON cr.customer_id = s.customer_id
GROUP BY 1,2
ORDER BY 3 desc

--



-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT * FROM
(
SELECT 
city_id,SUM(total) AS revenue,
EXTRACT (YEAR FROM sale_date) AS year,
EXTRACT(MONTH FROM sale_date) AS month,
EXTRACT(QUARTER FROM sale_date) AS qua
FROM customers cr
RIGHT JOIN sales
ON cr.customer_id = sales.customer_id

GROUP BY city_id, 3,5,4
ORDER BY 3
)
	WHERE year =2023 AND qua =4



-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?


SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC


-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city

WITH AA AS (
	SELECT city_name,SUM(total) AS totalsales,COUNT(DISTINCT s.customer_id)AS totalcustomers
	FROM city
	JOIN customers cr 
	ON city.city_id = cr.city_id
	JOIN sales s
	ON s.customer_id = cr.customer_id
	GROUP BY 1)
	SELECT *,ROUND(totalsales::NUMERIC/totalcustomers::NUMERIC,2) AS avgcitysale
	FROM AA 
	ORDER BY 


-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

	
	SELECT city_name, population,COUNT(DISTINCT customer_id) AS unique_cus,
	ROUND((population * 0.25)/1000000, 2) as coffee_consumers 
	FROM city c
	JOIN customers as cr
	ON c.city_id = cr.city_id
	GROUP BY 1,2


select * from city
select * from customers
select * from products
select * from sales



-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

WITH TABLEA AS
(
SELECT city_name,product_name, SUM(s.total) AS totalsales
FROM city c
JOIN customers as cs
ON c.city_id = cs.city_id
JOIN sales as s
ON cs.customer_id = s.customer_id
JOIN products as p
ON s.product_id = p.product_id
GROUP BY 1,2
ORDER BY 1,3 DESC),

TABLEB AS 
(
SELECT *,
RANK() OVER(PARTITION BY city_name ORDER BY totalsales DESC)
FROM TABLEA)
SELECT * FROM TABLEB WHERE RANK<=3




-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

select city_name, COUNT(DISTINCT customer_id)
from city
JOIN customers cr
ON city.city_id =cr.city_id
GROUP BY 1



-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer


WITH ta as(
	SELECT city_name,estimated_rent,SUM(total) AS totalsales,COUNT(DISTINCT cr.customer_id) AS distid
	FROM city c
	JOIN customers cr
	ON c.city_id = cr.city_id
	JOIN sales s
	ON cr.customer_id = s.customer_id
	GROUP BY 1,2
)
SELECT *, ROUND(totalsales::numeric /distid,2) AS avgsale, ROUND(estimated_rent::INTEGER/distid,2) AS avgrent FROM ta

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city


WITH aa AS 
(
	SELECT city_name,  EXTRACT(year from sale_date) as year, 
	EXTRACT(month from sale_date) as month,
	SUM(total) as totalsales
	FROM city c
	JOIN customers as cr
	ON c.city_id = cr.city_id
	JOIN sales s
	ON s.customer_id = cr.customer_id
	GROUP BY 1,2,3),
	ab as(	
		SELECT
			city_name,
			month,
			year,
			totalsales as cr_month_sale,
			LAG(totalsales, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM aa)
SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2) as growth_ratio

		FROM ab
		WHERE last_month_sale IS NOT NULL



-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers

WITH TABLEA AS
(
SELECT city_name,estimated_rent AS totalrent,COUNT(DISTINCT cr.customer_id) as totalcustomers,SUM(total) AS total_sale
FROM city c
JOIN customers cr
ON c.city_id = cr.city_id
JOIN sales s
ON cr.customer_id =s.customer_id 
GROUP BY 1,2
ORDER BY 4 DESC
LIMIT 4
)
SELECT *, totalrent/totalcustomers AS avg_rent from TABLEA

/*
-- Recomendation

City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.
	
City 2: Chennai

1.Highest total number of customers, which is 68.
2.Average rent per customer is 407(still under 500).

City 3: JAIPUR


1.Highest number of customers, which is 69.
2.Average Rent is very low
3.Customers count is good
	