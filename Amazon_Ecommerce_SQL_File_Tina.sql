-- SUBMISSION BY: TINA DIGAMBAR KAPSE
-- POWER BI PROJECT: AMAZON ECOMMERCE ANALYSIS
-- TOOLS USED: POWER BI DESKTOP, MYSQL WORKBENCH, MS-OFFICE
-- BATCH: PROFESSIONAL CERTIFICATE COURSE IN DATA SCIENCE - DECEMBER 2024

-- ==================================================== OBJECTIVE QUESTIONS ====================================================

-- OBJECTIVE ANSWER 14:	Identify the top 5 most valuable customers using a composite score that combines three key metrics: 
-- 		a.	Total Revenue (50% weight): The total amount of money spent by the customer.
-- 		b.	Order Frequency (30% weight): The number of orders placed by the customer, indicating their loyalty and engagement.
-- 		c.	Average Order Value (20% weight): The average value of each order placed by the customer, reflecting the typical transaction size.

WITH CustomerMetrics AS (
	SELECT 
		c.CustomerID,
		SUM(o.SalePrice) OVER (PARTITION BY c.CustomerID) AS TotalRevenue,
		COUNT(o.OrderID) OVER (PARTITION BY c.CustomerID) AS OrderFrequency,
		AVG(o.SalePrice) OVER (PARTITION BY c.CustomerID) AS AverageOrderValue
	FROM customers c
	JOIN orders o ON c.CustomerID = o.CustomerID
)
SELECT 
	DISTINCT CustomerID,
	TotalRevenue,
	OrderFrequency,
	AverageOrderValue,
	(TotalRevenue * 0.5 + OrderFrequency * 0.3 + AverageOrderValue * 0.2) AS CompositeScore
FROM CustomerMetrics
ORDER BY CompositeScore DESC
LIMIT 5;

-- -----------------------------------------------------------------------------------------------------------------------------
-- OBJECTIVE ANSWER 15: Calculate the month-over-month growth rate in total revenue across the entire dataset. 

WITH MonthlyRevenue AS (
    SELECT 
		EXTRACT(YEAR FROM OrderDate) AS Year,
		EXTRACT(MONTH FROM OrderDate) AS Month,
		SUM(SalePrice) AS TotalRevenue
    FROM orders
    GROUP BY Year, Month
)
SELECT 
	Year,
	Month,
    TotalRevenue,
	(
    (TotalRevenue - LAG(TotalRevenue) OVER (ORDER BY Year, Month)) 
    / 
    LAG(TotalRevenue) OVER (ORDER BY Year, Month) * 100
    ) AS MoMGrowthRate
FROM MonthlyRevenue
ORDER BY Year, Month;

-- -----------------------------------------------------------------------------------------------------------------------------
-- OBJECTIVE ANSWER 16:	Calculate the rolling 3-month average revenue for each product category. 

WITH MonthlyRevenue AS (
    SELECT 
		EXTRACT(YEAR FROM OrderDate) AS Year,
		EXTRACT(MONTH FROM OrderDate) AS Month,
		ProductCategory,
        SUM(SalePrice) AS TotalRevenue
    FROM orders
    GROUP BY Year, Month, ProductCategory
)
SELECT 
	Year,
    Month,
    ProductCategory,
	AVG(TotalRevenue) OVER (PARTITION BY ProductCategory ORDER BY Year, Month
	ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Rolling3MonthAvgRevenue
FROM MonthlyRevenue
ORDER BY Year, Month;

-- -----------------------------------------------------------------------------------------------------------------------------
-- OBJECTIVE ANSWER 17: Update the orders table to apply a 15% discount on the `Sale Price` for orders placed by customers who have made at least 10 orders.

UPDATE orders
SET SalePrice = SalePrice * 0.85
WHERE CustomerID IN (
    SELECT CustomerID
    FROM orders
    GROUP BY CustomerID
    HAVING COUNT(OrderID) >= 10
);

-- -----------------------------------------------------------------------------------------------------------------------------
-- OBJECTIVE ANSWER 18: Calculate the average number of days between consecutive orders for customers who have placed at least five orders.

WITH CustomerOrders AS (
    SELECT 
		CustomerID, 
        OrderID, 
        OrderDate,
		LEAD(OrderDate) OVER (
			PARTITION BY CustomerID 
            ORDER BY OrderDate
        ) AS NextOrderDate
    FROM orders
)
SELECT 
	CustomerID,
    AVG(
		DATEDIFF(NextOrderDate, OrderDate)
    ) AS AvgDaysBetweenOrders
FROM CustomerOrders
WHERE NextOrderDate IS NOT NULL
GROUP BY CustomerID
HAVING COUNT(OrderID) >= 5;

-- -----------------------------------------------------------------------------------------------------------------------------
-- OBJECTIVE ANSWER 19: Identify customers who have generated revenue that is more than 30% higher than the average revenue per customer.

WITH TotalCustomerRevenue AS (
    SELECT 
		CustomerID,
        SUM(SalePrice) AS TotalRevenue
    FROM orders
    GROUP BY CustomerID
),
AverageRevenue AS (
    SELECT AVG(SalePrice) AS AvgRevenue 
    FROM orders
)
SELECT 
	t.CustomerID, 
	t.TotalRevenue
FROM TotalCustomerRevenue t, AverageRevenue a
WHERE t.TotalRevenue > a.AvgRevenue * 1.30;

-- -----------------------------------------------------------------------------------------------------------------------------
-- OBJECTIVE ANSWER 20: Determine the top 3 product categories that have shown the highest increase in sales over the past year compared to the previous year. 
SELECT 
	a.ProductCategory,
    a.TotalSales AS CurrentYearSales,
    b.TotalSales AS PreviousYearSales,
    a.TotalSales - b.TotalSales AS SalesIncrease
FROM (
	SELECT ProductCategory, SUM(SalePrice) AS TotalSales
	FROM orders
	WHERE YEAR(OrderDate) = 2020  
    GROUP BY ProductCategory
) as a  
JOIN (
	SELECT ProductCategory, SUM(SalePrice) AS TotalSales
	FROM orders
    WHERE YEAR(OrderDate) = 2019 
    GROUP BY ProductCategory
) as b  
ON a.ProductCategory = b.ProductCategory 
ORDER BY SalesIncrease DESC 
LIMIT 3; 