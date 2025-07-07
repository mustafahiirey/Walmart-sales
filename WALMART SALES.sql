-- CHANGING COLUMN NAME
EXEC sp_rename 'WalmartSales.Time', 'time_payment', 'COLUMN';

-- add new column for month name
alter table WalmartSales
add  month_name varchar(200);
UPDATE WalmartSales
SET month_name = datename(month,Date);

-- add new column for day name of the week
alter table WalmartSales
add  day_name varchar(200);
UPDATE WalmartSales
SET day_name = datename(WEEKDAY,Date);

-- Add the time_of_day column
ALTER TABLE walmartsales ADD  time_of_day VARCHAR(20);
UPDATE WalmartSales
SET time_of_day = (
	CASE
		WHEN time_payment >= '00:00:00' AND time_payment < '12:00:00' THEN 'Morning'
		WHEN time_payment >= '12:00:00' AND time_payment < '16:00:00' THEN 'Afternoon'
		ELSE 'Evening'
	END
);

---------------------------		GENRIC QUESTION -------------------
-- How many unique cities does the data have?
SELECT 
	DISTINCT City
FROM WalmartSales
--In which city is each branch?
SELECT 
	DISTINCT City,
	Branch
FROM WalmartSales

---------------------- PRODUCT QUESTIONS ----------------------------
-- How many unique product lines does the data have?
SELECT
	DISTINCT Product_line
FROM WalmartSales
-- What is the most selling product line?
SELECT
	 Product_line,
	 ROUND(SUM(Quantity),2) AS PRODUCT_LINE_SALES
FROM WalmartSales
GROUP BY Product_line
ORDER BY PRODUCT_LINE_SALES DESC
-- What is the total revenue by month
SELECT
	 MONTH_NAME,
	 ROUND(SUM(Total),2) AS TOTAL_REVENUE
FROM WalmartSales
GROUP BY MONTH_NAME
ORDER BY TOTAL_REVENUE DESC
-- What month had the largest COGS?
SELECT
	 MONTH_NAME,
	 ROUND(SUM(cogs),2) AS TOTAL_COGS
FROM WalmartSales
GROUP BY MONTH_NAME
ORDER BY TOTAL_COGS DESC
-- What product line had the largest revenue?
SELECT
	 Product_line,
	 ROUND(SUM(Total),2) AS TOTAL_REVENUE
FROM WalmartSales
GROUP BY Product_line
ORDER BY TOTAL_REVENUE DESC
-- What is the city and branch with the largest revenue?
SELECT
	 City,BRANCH,
	 ROUND(SUM(Total),2) AS CITY_REVENUE
FROM WalmartSales
GROUP BY City,Branch
ORDER BY CITY_REVENUE DESC
-- What product line had the largest AVG VAT?
SELECT
	 Product_line,
	 ROUND(AVG(Tax_5),2) AS AVG_VAT
FROM WalmartSales
GROUP BY Product_line
ORDER BY AVG_VAT DESC
-- Fetch each product line and add a column to those product line showing "Good", "Bad". Good if its greater than average sales
 -- Step 1: calculate total per product line
WITH CTE_PRODUCT_LINE AS (
    SELECT
        product_line,
        SUM(total) AS total
    FROM WalmartSales 
    GROUP BY product_line
),
-- Step 2: calculate overall average of those totals
CTE_AVG AS (
    SELECT AVG(total) AS avg_sales FROM CTE_PRODUCT_LINE
)

-- Step 3: join both to compare
SELECT 
    p.product_line,
    p.total,
    a.avg_sales,
    CASE 
        WHEN p.total > a.avg_sales THEN 'Good'
        WHEN p.total = a.avg_sales THEN 'Average'
        ELSE 'Bad'
    END AS remark
FROM CTE_PRODUCT_LINE p
CROSS JOIN CTE_AVG a;
-- Which branch sold more products than average product sold?
SELECT
	Branch,
	SUM(Total) AS TOTAL_SALES
FROM WalmartSales
GROUP BY Branch
HAVING SUM(Total) > (SELECT AVG(TOTAL) AS AVG_SALES FROM WalmartSales)
-- What is the most common product line by gender
SELECT
	Gender,
	Product_line,
	COUNT(Gender) AS COUNTS
FROM WalmartSales
GROUP BY Product_line,Gender
ORDER BY Product_line
-- What is the average rating of each product line AND RANK IT
SELECT
	Product_line,
	ROUND(AVG(Rating),2) AS AVG_RATING,
	DENSE_RANK() OVER(ORDER BY ROUND(AVG(Rating),2) DESC) AS RANK_RATING
FROM WalmartSales
GROUP BY Product_line
ORDER BY AVG_RATING DESC
-- -------------------------- Customers -------------------------------
-- How many unique customer types does the data have?
SELECT
	DISTINCT Customer_type
FROM WalmartSales
-- How many unique payment methods does the data have?
SELECT
	DISTINCT Payment
FROM WalmartSales
-- What is the most common customer type?
SELECT
	Customer_type,
	COUNT(Customer_type) AS COUNT_CUSTOMER_TYPE
FROM WalmartSales
GROUP BY Customer_type
ORDER BY COUNT_CUSTOMER_TYPE DESC
-- What is the gender of most of the customers?
SELECT
	Gender,
	COUNT(*) AS COUNT_CUSTOMER_GENDER
FROM WalmartSales
GROUP BY Gender
ORDER BY COUNT_CUSTOMER_GENDER DESC
-- What is the gender distribution per branch?
SELECT
	Branch,
	Gender,
	COUNT(*) AS GENDER_BRANCH
FROM WalmartSales
GROUP BY Gender,Branch
ORDER BY Branch
-- Which time of the day do customers give most ratings?
SELECT
	TIME_OF_DAY,
	ROUND(AVG(Rating),2) AS AVG_RATING
FROM WalmartSales
GROUP BY TIME_OF_DAY
ORDER BY AVG_RATING DESC
/* NOTE :-- Looks like time of the day does not really affect the rating,
its more or less the same rating each time of the day*/

-- Which time of the day do customers give most ratings per branch?
SELECT
	Branch,
	TIME_OF_DAY,
	ROUND(AVG(Rating),2) AS AVG_RATING
FROM WalmartSales
GROUP BY Branch,TIME_OF_DAY
ORDER BY AVG_RATING DESC
/* -- Branch A and C are doing well in ratings, 
branch B needs to do a  little more to get better ratings.*/

-- Which day fo the week has the best avg ratings?
SELECT
	DAY_NAME,
	ROUND(AVG(Rating),2) AS AVG_RATING
FROM WalmartSales
GROUP BY DAY_NAME
ORDER BY AVG_RATING DESC
/* -- Mon, Tue and Friday are the top best days for good ratings
 why is that the case, how many sales are made on these days? */
 SELECT
	DAY_NAME,
	ROUND(SUM(Quantity),2) AS TOTAL_QUANTITY,
	ROUND(SUM(Total),2) AS TOTAL_REVENUE
FROM WalmartSales
GROUP BY DAY_NAME
ORDER BY TOTAL_QUANTITY DESC
/* NOT MUCH SALES WERE MADE IN THOSE DAYS SHOWING THE BIG RATING THOSE DAYS GOT
DEPEND ON OTHER FACTORS SUCH AS CUSTOMER SATISFACTION,ETC */

-- Which day of the week has the best average ratings per branch?
SELECT
	DAY_NAME,
	Branch,
	ROUND(AVG(Rating),2) AS AVG_RATING
FROM WalmartSales
GROUP BY DAY_NAME,Branch
ORDER BY AVG_RATING DESC

-- ---------------------------- Sales ---------------------------------
-- Number of sales made in each time of the day per weekday?
SELECT
	TIME_OF_DAY,
	COUNT(QUANTITY) AS SALES_MADE
FROM WalmartSales
GROUP BY TIME_OF_DAY
ORDER BY SALES_MADE DESC
--NOTE :Evenings experience most sales, the stores are filled during the evening hours

-- Which of the customer types brings the most revenue?
SELECT
	Customer_type,
	ROUND(SUM(Total),2) AS TOTAL_REVENUE
FROM WalmartSales
GROUP BY Customer_type
ORDER BY TOTAL_REVENUE DESC
-- Which city has the largest tax/VAT percent?
SELECT
	City,
	ROUND(AVG(Tax_5),2) AS AVG_TAX
FROM WalmartSales
GROUP BY City
ORDER BY AVG_TAX
-- Which customer type pays the most in VAT?
SELECT
	Customer_type,
	ROUND(AVG(Tax_5),2) AS AVG_TAX
FROM WalmartSales
GROUP BY Customer_type
ORDER BY AVG_TAX DESC






