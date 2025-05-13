--Check out the data in our business table
--view all data from sales table
SELECT * FROM sales;
--view all data from customers table
SELECT * FROM customers;
--view all data from products table
SELECT * FROM products;
--view all data from city table
SELECT * FROM city;

--Analysis Based on Business Questions
--	Q1. Coffee Consumers Count
--How many people in each city are estimated to consume consume coffee,
--Given that 25% of the population does?
SELECT
    city_name,
    population,
	city_rank,
  ROUND((0.25*population)/1000000,2) AS "coffee_consumers(Millions)"
FROM city 
ORDER BY 4 DESC
--Question 2:Total Revenue from Coffee Sales
/*What is the total revenue generated from coffee sales across all cities in the 
last quarter of 2023? */
SELECT 
  *
FROM
(
SELECT
      ct.city_name,
      SUM(sal.total)AS total_revenue,
	  EXTRACT (YEAR FROM sal.sale_date)AS sale_year,
	  EXTRACT(quarter FROM sal.sale_date)AS quarter
FROM sales sal
JOIN customers cust
ON sal.customer_id = cust.customer_id
JOIN city ct
ON cust.city_id = ct.city_id
GROUP BY 1,3,4 
)a
WHERE sale_year = 2023
AND quarter = 4
ORDER BY total_revenue DESC

--Question 3: Sales Count for Each Product
--How many units of each coffee product have been sold?
SELECT 
       prod.product_name,
       sal.product_id,
       COUNT (sal.sale_id)AS unique_product_count	   
FROM sales sal
LEFT JOIN products prod
ON sal.product_id = prod.product_id
GROUP BY 1 ,2
ORDER BY unique_product_count DESC
---Question 4: Average Sales Amount per City
--What is the average sales amount per customer in each city?

SELECT 
		ct.city_name,
		SUM(sal.total) AS total_revenue,
		COUNT(DISTINCT sal.customer_id)AS total_customers,
		ROUND (SUM(sal.total::NUMERIC)/COUNT(DISTINCT sal.customer_id),2) AS "Average Sale Per Customer"
FROM sales sal
JOIN customers cust
ON sal.customer_id = cust.customer_id
LEFT JOIN city ct
ON cust.city_id = ct.city_id
GROUP BY 1
ORDER BY 2 DESC
---Question 5. City Population and Coffee Consumers
/* Provide a list of cities along with their populations and estimated coffee consumers

return city_name,total current customers ,estimated coffee consumers*/
SELECT
        ct.city_name,
		ct.population,
		COUNT(DISTINCT cust.customer_id)AS current_customers,
		ROUND((0.25*ct.population)/1000000,2) AS "estimated_cofee_consumers(Millions)"
FROM city ct
JOIN customers cust
ON ct.city_id = cust.city_id
JOIN sales sal
ON cust.customer_id = sal.customer_id
GROUP BY 1,2,4
ORDER BY 4 DESC
--Question 6: Top Selling Products by City
/*What are the top 3 selling products in each city based on sales volume?*/
WITH top_selling 
AS
(
SELECT 
       prod.product_name,
	   ct.city_name,
	   COUNT(sal.sale_id)AS sales_volume,
	   SUM(sal.total)AS total_sales,
	   DENSE_RANK() OVER(PARTITION BY ct.city_name ORDER BY COUNT(sal.sale_id) DESC)AS rank
FROM products prod
JOIN sales sal
ON  prod.product_id = sal.product_id
JOIN customers cust
ON sal.customer_id = cust.customer_id
JOIN city ct
ON cust.city_id =  ct.city_id
GROUP BY 1,2
)
SELECT  
       *
FROM top_selling
WHERE RANK <= 3
--Question 7: Consumer Segmentation by city
/*How many unique customers are there in each city who have purchased coffee products?*/
SELECT 
        ct.city_name,
        COUNT(DISTINCT cust.customer_id)AS unique_customers
FROM sales sal
JOIN customers cust
ON sal.customer_id = cust.customer_id
JOIN city ct
ON cust.city_id =  ct.city_id
GROUP BY 1
ORDER BY 1 
--Question 8:Average Sale Vs Rent
--Find each city and their average sale per customer and average rent per customer
SELECT 
           ct.city_name,
		   ct.estimated_rent,
		   COUNT(DISTINCT cust.customer_id)AS unique_customers,
		   SUM(sal.total)AS total_sales,
		   ROUND(SUM(sal.total::NUMERIC)/COUNT(DISTINCT cust.customer_id),2)AS avg_sale_per_customer,
		   ROUND(ct.estimated_rent::NUMERIC/COUNT(DISTINCT cust.customer_id),2) AS avg_rent_per_customer
FROM  Sales sal
JOIN customers cust
ON sal.customer_id = cust.customer_id
JOIN city ct
ON cust.city_id =ct.city_id
GROUP BY 1,2
ORDER BY 5 DESC --order by avg_sale_per_customer
--Question 9: Monthly Sales Growth
/*Sales growth rate:Calculate the percentage growth(or decline) in sales 
over different time periods (monthly)*/
WITH monthly_sales
AS
(
SELECT 
        ct.city_name,
		EXTRACT(YEAR FROM sal.sale_date)AS year,
        EXTRACT(MONTH FROM sal.sale_date)AS month,
		SUM(sal.total)AS total_sales
FROM sales sal
JOIN customers cust
ON sal.customer_id = cust.customer_id
JOIN city ct
ON cust.city_id = ct.city_id
GROUP BY 1,2,3
ORDER BY 1,2,3
),
growth_ratio
AS
(
	SELECT
	       city_name,
		   year,
		   month,
		   total_sales AS current_month_sale,
		   LAG(total_sales,1)OVER(PARTITION BY  city_name ORDER BY year,month )AS last_month_sales
	FROM   monthly_sales
)
SELECT
          city_name,
		   year,
		   month,
		   current_month_sale,
		   last_month_sales,
		   ROUND((current_month_sale-last_month_sales)::numeric/last_month_sales::numeric *100,2) AS growth_ratio
FROM growth_ratio
WHERE last_month_sales IS NOT NULL
--Question 10: Market Potential Analysis
/*Identify top 3 city based on highest sales...
return city name,total sale,total rent,total customers,estimated coffee consumers
*/
WITH top_3_city
AS
(
	SELECT
	      ct.city_name,
		  ct.population,
		  SUM(sal.total)AS total_sales,
		  ct.estimated_rent AS total_rent,
		  COUNT(DISTINCT cust.customer_id)AS unique_customers,
		  ROUND((0.25*ct.population/1000000),2)AS "estimated_coffee_consumers(Mn)"
	FROM sales sal
	JOIN customers cust
	ON sal.customer_id =  cust.customer_id
	JOIN city ct
	ON cust.city_id = ct.city_id
	GROUP  BY 1,2,4,6
	ORDER BY total_sales DESC
)
SELECT
       city_name,
	   population,
	   total_sales,
	  ROUND(total_sales::numeric/unique_customers,2) AS avg_sale_per_customer,
	   total_rent,
	  ROUND(total_rent::numeric/unique_customers,2) AS avg_rent_per_customer,
	   unique_customers,
	   "estimated_coffee_consumers(Mn)"
FROM top_3_city
/*
--Recommendation
City 1: Pune

1. High Sales and Customer Spending: Pune leads with $1,258,290 in total sales and an average sale per customer of $24,197.88, 
2. Low Rent Costs Relative to Sales: With a total rent of $15,300 and an average rent per customer of $294.23
3. Pune’s rent is manageable compared to its high sales, ensuring better profitability.

City 2:  Chennai

1.Strong Sales and Customer Base: Chennai has $944,120 in total sales and 42 unique customers, 
  with an average sale per customer of $22,479.05,
2.Affordable Rent Costs:The total rent in Chennai is $17,100, with an average rent per customer of $407.14, 
  which is reasonable given the sales volume, making it a cost-effective choice


City 3: Bangalore

1.High Sales and Large Customer Reach:Bangalore records $860,110 in total sales and has 39 unique customers,
  with an average sale per customer of $22,054.10
  
2. Moderate Rent Costs: Bangalore’s total rent is $29,700, with an average rent per customer of $761.54,
   which is higher but justifiable given the sales and the city’s large coffee consumer base
   (3.08 million estimated coffee consumers).

*/
