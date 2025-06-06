SELECT * FROM sales;
SELECT * FROM product;
SELECT * FROM customer;

/* Pattern Matching */


-- and last name starts with "a/b/c/d"
SELECT customer_name
FROM customer WHERE customer_name~*'^[a-z]{5}\s(a|b|c|d)[a-z]{5}$';

Create Table zipcode(ZIP_codes varchar(255));

INSERT INTO zipcode VALUES (234432), (23345),('sdfe4'),('123&3'),(67424),
(2895432),(12312);

SELECT * from zipcode;

--Find out the valid zipcodes from this table (5 or 6 Numeric Characters)
SELECT zip_codes 
FROM zipcode where zip_codes~*'^[0-9]{5,6}$';

SELECT * from users;

SELECT name
FROM users where name~*'[^a-z0-9\.\-\_]+@[a-z0-9]\.[a-z]{2,5}$';-- Extract All Valid Email Addresses



SELECT count(name) as no_of_valid_email
FROM users WHERE name~* '[a-z0-9\.\-\_]+@[a-z0-9\.]+[a-z]{2,5}$';-- Count the Number of Valid Email Addresses

update users
set name ='invalid'
WHERE name !~* '[a-z0-9\.\-\_]+@[a-z0-9\.]+[a-z]{2,5}$';--Update Invalid Emails
------------------------------------------------------------------------------------------------------------------------

/* WINDOW FUNCTIONS */

SELECT * from customer limit 10;

SELECT * from sales limit 10;

SELECT a.*,b.order_num,b.sales_tot,b.quantity_tot,b.profit_tot
from customer as a
left join (select customer_id, count(distinct order_id)
			as order_num,sum(sales)AS sales_tot, sum(quantity) as quantity_tot,
			sum(profit) as profit_tot from sales group by customer_id) as b
ON a.customer_id=b.customer_id;

SELECT * from sales where customer_id = 'AA-10315' order by order_id;

CREATE TABLE customer_order as (SELECT a.*,b.order_num,
			b.sales_tot,b.quantity_tot,b.profit_tot
from customer as a
left join (select customer_id, count(distinct order_id) as 
			order_num,sum(sales)AS sales_tot, sum(quantity) as quantity_tot,
			sum(profit) as profit_tot from sales group by customer_id) as b
ON a.customer_id=b.customer_id);

SELECT * from customer_order;

SELECT customer_id, customer_name, state, order_num,
	row_number() over (PARTITION by state order by order_num DESC) as row_n
FROM customer_order;

SELECT * from (SELECT customer_id, customer_name, state, order_num,
	row_number() over (PARTITION by state order by order_num DESC) as row_n
FROM customer_order) as a where a.row_n<=3;


/* WINDOW FUNCTION EXERCISE */
SELECT * FROM customer;
SELECT * FROM sales;
SELECT * from product;

-- Generating Row Numbers for All rows Accordingly
SELECT 
	b.customer_id,
	b.region,
	a.sales,
	c.category,
	ROW_NUMBER() OVER (ORDER BY a.customer_id ASC) as row_num
FROM sales as a
LEFT JOIN (select customer_id,region FROM customer) as b
ON a.customer_id=b.customer_id
RIGHT JOIN (select product_id, category from product) as c
ON a.product_id=c.product_id;

-- Generating Row Numbers Partitioned by Category and Ordered by Region

SELECT
	b.customer_id,
	b.region,
	a.sales,
	c.category,
	ROW_NUMBER() OVER (PARTITION BY c.category ORDER BY b.region ASC) as row_num
FROM sales as a
LEFT JOIN (select customer_id, region from customer) as b
ON a.customer_id=b.customer_id
RIGHT JOIN (select product_id, category from product) as c
ON a.product_id=c.product_id;

-- Removing Duplicate Rows Using ROW_NUMBER()


SELECT
	b.customer_id,
	b.region,
	a.sales,
	c.category,
	ROW_NUMBER() OVER (PARTITION BY c.category ORDER BY b.customer_id ASC) as row_num
FROM sales as a
LEFT JOIN (select customer_id, region from customer) as b
ON a.customer_id=b.customer_id
RIGHT JOIN (select product_id, category from product) as c
ON a.product_id=c.product_id;


DELETE FROM sales
WHERE customer_id IN(
	Select customer_id
	from regional_sales
	where row_num >1
);

/* Top N Analysis*/
-- For thesame table

SELECT
	customer_id,
	sales,
	profit,
	ship_mode
FROM(
	select
		customer_id,
		sales,
		profit,
		ship_mode,
		row_number() over (partition by ship_mode order by sales desc) as row_num
	from sales
) AS ranked_customer_id
where row_num<=3;

--Using differnt Tables
CREATE VIEW ranked_customer_sales AS
select 
	b.customer_name,
	a.sales,
	c.sub_category,
	a.profit,
	row_number() over (partition by c.sub_category order by a.profit desc) as row_num 
from sales as a
left join (select customer_id,customer_name from customer) as b
on a.customer_id=b.customer_id
right join (select product_id,sub_category from product) as c
on a.product_id=c.product_id;

SELECT * from ranked_customer_sales
WHERE row_num<=2;-- Top sales and categories by customers.


/* WINDOW FUNCTIONS workings */

-- Identify the Most Recent Order per Customer

SELECT * FROM customer;
SELECT * from sales;
SELECT * FROM product;

CREATE VIEW  Recent_Sales_per_Customer AS
SELECT 
	a.customer_name,
	b.order_id,
	b.order_date,
	b.sales,
	ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY b.order_date) as row_num
FROM sales as b
LEFT JOIN (select customer_id, customer_name from customer) as a
on a.customer_id=b.customer_id;

DROP VIEW recent_sales_per_customer;

SELECT * from Recent_Sales_per_Customer
WHERE row_num<=2 limit 10;

-- Top 3 Most Frequently Purchased Products by Each Customer

CREATE VIEW products_by_each_customer AS
SELECT 
	a.customer_id,
	c.sub_category,
	count(*) as purchase_count,
	ROW_NUMBER() OVER (PARTITION BY a.customer_id ORDER by count(*) desc) as row_num
FROM sales as a
RIGHT join (select product_id, sub_category from product) as c
on a.product_id=c.product_id
GROUP by a.customer_id,c.sub_category;

SELECT * FROM products_by_each_customer
where row_num<=3
Limit 20;


-- Find the Top N Sales per Product Category by Revenue

CREATE VIEW top_sales_per_product_category_by_revenue AS
SELECT
	c.sub_category,
	b.sales,
	(b.sales * b.quantity) as revenue,
	row_number() over (partition by c.sub_category order by (b.sales * b.quantity)) as row_num
FROM sales as b
right join (select product_id, sub_category from product)as c
on b.product_id=c.product_id;



SELECT * from top_sales_per_product_category_by_revenue
WHERE row_num<=1;


/* RANK */

SELECT * FROM customer;
SELECT * from sales;
SELECT * FROM product;

-- Ranking all Customers by sales
SELECT
	b.customer_name,
	a.sales,
	c.category,
	RANK() OVER (ORDER BY a.sales desc) as ranks 
FROM sales as a
LEFT join (select customer_id,customer_name from customer) as b
	on a.customer_id=b.customer_id
RIGHT join (select product_id,category from product) as c
	on a.product_id=c.product_id;

-- Ranking Customers by sales in each category
SELECT
	b.customer_name,
	a.sales,
	c.category,
	RANK() OVER (PARTITION BY c.category ORDER BY a.sales desc) as ranks  
FROM sales as a
LEFT join (select customer_id,customer_name from customer) as b
	on a.customer_id=b.customer_id
RIGHT join (select product_id,category from product) as c
	on a.product_id=c.product_id;

--  Using RANK() to Find the Top N Salaries with Ties

CREATE VIEW customer_sales_ranks AS
SELECT
	b.customer_name,
	a.sales,
	c.category,
	RANK() OVER (PARTITION BY c.category ORDER BY a.sales desc) as ranks  
FROM sales as a
LEFT join (select customer_id,customer_name from customer) as b
	on a.customer_id=b.customer_id
RIGHT join (select product_id,category from product) as c
	on a.product_id=c.product_id;

SELECT * from customer_sales_ranks
WHERE ranks<=3;
--------------------------------------------------------------------------------------------------------
/* DENSE_RANK */


CREATE VIEW sub_category_profit AS
SELECT
	c.sub_category,
	b.product_id,
	b.profit,
	DENSE_RANK() OVER (PARTITION BY c.sub_category ORDER BY b.profit DESC) as dense_rank
FROM sales as b
RIGHT JOIN (select product_id,sub_category from product) as c
ON b.product_id=c.product_id;

SELECT * from sub_category_profit
WHERE dense_rank<= 10;

/* NTILE */


SELECT customer_id, customer_name,state, order_num,
row_number() OVER (partition by state order by order_num desc) as row_n,
rank() OVER (PARTITION BY state ORDER BY order_num DESC) as rank_n,
dense_rank() OVER (PARTITION BY state ORDER BY order_num DESC) as d_rank_n,
NTILE(5) OVER (PARTITION BY state ORDER BY order_num DESC) as tile_n
FROM customer_order;


SELECT * FROM(	
	SELECT
		customer_id,
		sales,
		NTILE(2) OVER (PARTITION BY customer_id ORDER BY sales desc ) as bucket 
	FROM sales
) WHERE bucket<=2 LIMIT 40;



SELECT	
	a.customer_id,
	a.region,
	c.sub_category,
	b.profit,
	NTILE(3) OVER (PARTITION BY a.customer_id ORDER BY b.profit DESC) as bucket_num
FROM customer as a
LEFT JOIN (select product_id, customer_id, profit from sales) as b
ON a.customer_id=b.customer_id
RIGHT JOIN (select product_id, sub_category from product) as c
ON b.product_id=c.product_id

SELECT * FROM(SELECT
	a.customer_name,
	c.sub_category,
	b.sales,
	NTILE(4) OVER (PARTITION BY a.customer_name ORDER BY sales DESC) as bucket_num
FROM customer AS a
RIGHT JOIN (select customer_id,product_id, sales from sales) as b
ON a.customer_id=b.customer_id
LEFT JOIN(select product_id, sub_category from product) as c
ON b.product_id=c.product_id)
WHERE bucket_num<=4;


-- ===============================

SELECT * FROM
	(SELECT 
	b.customer_name,
	a.sales,
	c.sub_category,
	NTILE(4) OVER (PARTITION BY b.customer_name ORDER BY a.sales DESC) as bucket_num,
	DENSE_RANK() OVER (PARTITION BY b.customer_name ORDER BY c.sub_category DESC) as ranked_num 
FROM sales as a
RIGHT JOIN (select product_id,sub_category from product) as c
ON a.product_id=c.product_id
LEFT JOIN (select customer_id, customer_name from customer) as b
ON a.customer_id=b.customer_id)
WHERE ranked_num <5 and customer_name Like '____ _____'; 

-- AVERAGE FUNCTION
SELECT * FROM customer_order;

SELECT
	customer_id,
	customer_name,
	state,
	sales_tot as revenue,
	avg(sales_tot) OVER (PARTITION BY state) as avg_revenue
FROM customer_order;

-- Customer with less than avg revenue

SELECT * FROM(SELECT
	customer_id,
	customer_name,
	state,
	sales_tot as revenue,
	avg(sales_tot) OVER (PARTITION BY state) as avg_revenue
FROM customer_order) as a WHERE a.revenue < a.avg_revenue;

-- COUNT

SELECT
	customer_id,
	customer_name,
	state,
	sales_tot as revenue,
	COUNT(customer_id) OVER (PARTITION BY state) as customer_count
FROM customer_order;

-- SUMTOTAL

CREATE TABLE order_rollup as SELECT 
	order_id, 
	max(order_date) as order_date,
	max(customer_id) as customer_id,
	sum(sales) as sales
FROM sales
GROUP BY order_id;

CREATE TABLE order_rollup_state as 
	select 
		a.*,
		b.state
	FROM order_rollup as a
	LEFT JOIN customer as b
ON a.customer_id = b.customer_id;

SELECT * FROM order_rollup_state;

SELECT
	*,
	SUM(sales) OVER (PARTITION BY state) as sales_state_total
FROM order_rollup_state;


-- RUNNING TOTAL
SELECT
	*,
	SUM(sales) OVER (PARTITION BY state) as sales_state_total,
	SUM(sales) OVER (PARTITION BY state ORDER BY order_date) as running_total
FROM order_rollup_state;

-- Exercise
(SELECT 
	a.customer_id,
	order_id,
	customer_name,
	sum(sales) as total_sales,
	region,
	NTILE(5) OVER (PARTITION BY b.region ORDER BY b.region) as bucket_num 
FROM sales as a
LEFT JOIN (SELECT customer_id, customer_name, region from customer) as b
ON a.customer_id=b.customer_id
GROUP BY 
	a.customer_id,
	order_id,
	customer_name,
	sales,
	region
) WHERE region Like 'East';


SELECT * FROM order_rollup_state;
SELECT * from product;

SELECT
	customer_id,
	order_date,
	order_id,
	sales,
	lag(sales,1) over (PARTITION BY customer_id ORDER BY order_date) as previous_sales,
	lag(order_id,1) OVER (PARTITION BY customer_id ORDER BY order_date) as previous_order_id
FROM order_rollup_state;

SELECT
	customer_id,
	order_date,
	order_id,
	sales,
	lead(sales,1) over (PARTITION BY customer_id ORDER BY order_date) as previous_sales,
	lead(order_id,1) OVER (PARTITION BY customer_id ORDER BY order_date) as previous_order_id
FROM order_rollup_state;	


-- Exercise 1: Track Changes in Sales Amounts
-- Objective: For each customer, calculate the difference in sales amount compared to their previous sale. 
-- Use the LAG() function to retrieve the previous sale amount and compute the difference.

SELECT 
	customer_id,
	order_date,
	sales,
	LAG(sales) OVER (PARTITION BY customer_id ORDER BY order_date) as previous_sales_amount,
	sales - LAG(sales) OVER (PARTITION BY customer_id ORDER BY order_date) as difference_from_previous
FROM order_rollup_state;

--: Calculate Time to Next Sale


SELECT
	customer_id,
	order_date,
	sales,
	LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY sales) as next_sales_date,
	order_date - LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY sales) as days_until_next_sale
FROM order_rollup_state;

--Exercise 3: Compare Prices of Current and Next Product
-- Objective: For each product in the product table, compare the price of the current product with the next product in alphabetical order of the product name.
-- Use the LEAD() function to retrieve the next product's price.

SELECT 
	a.product_id,
	a.sub_category,
	b.sales,
	LEAD(a.sub_category,1) OVER (ORDER BY a.sub_category) as next_product_name,
	LEAD(b.sales,1) OVER (ORDER BY a.sub_category) as next_price
FROM product as a
LEFT JOIN (select product_id,sales from sales) as b
ON a.product_id=b.product_id;


-- : Identify Price Drops in Product Sales
-- Objective: For each product sold, determine whether the price has dropped compared to the previous sale of the same product. 


SELECT
	b.product_id,
	a.order_date,
	a.sales,
	LAG(a.sales,1) OVER (ORDER BY a.order_date) as previous_price,
	CASE
		WHEN a.sales < LAG(a.sales,1) OVER (ORDER BY a.order_date) THEN 'TRUE'
		ELSE 'FALSE'
		END AS Price_Drop
FROM sales as a
LEFT JOIN (select product_id from product) as b
ON a.product_id=b.product_id;


-- Calculate Customer’s Next Purchase Value
-- Objective: For each customer, calculate how much they spent on their next purchase. Use the LEAD() function to retrieve the next sale amount.




SELECT
	customer_id,
	order_date,
	sales,
	LEAD(sales) OVER (PARTITION BY customer_id ORDER BY order_date) as next_purchase_amount
FROM sales;


-- COALESCE

SELECT * from emp_name;

SELECT *,
	coalesce(first_name,middle_name,last_name) as name_corr,
	concat(first_name,middle_name,last_name) as name_concat
FROM emp_name;

/* CONVERSIONS */

-- NUMBER AND DATE TO A STRING
SELECT
	sales,
	'Total sales value for this is  order is '|| to_char (sales, 'L9,999.99') as message
FROM sales;

SELECT
	order_date,
	to_char(order_date,'Month DD YYYY')
FROM sales;

-- STRING TO NUMBER OR DATE

SELECT	to_date('2019/01/15', 'YYYY/MM/DD');
SELECT to_date('26122018','DDMMYYYY');

SELECT to_number('2045.876','9999.999');
SELECT to_number('$2,045.876','L9,999.999');


SELECT
	profit,
	concat('The profit is: ',to_char(profit,'L9999'))
FROM sales;

SELECT to_date('10/February/2024', 'DD/Month/YYYY');
