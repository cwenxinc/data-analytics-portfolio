-- =======================================================================
-- This script uses subqueries and Common Table Expressions (CTEs) to 
-- evaluate whether July 2026 is a favorable time for sellers to list 
-- properties in Sacramento.

-- Historically, Sacramento has experienced lower housing inventory 
-- in July while transaction volume has remained relatively high, 
-- suggesting strong buyer demand despite limited supply. Additionally, 
-- homes have typically sold for 0.35% above the asking price, and 
-- more than 40% of active listings are priced above the historical 
-- average sold price by an average of 7%.
-- The combination of constrained inventory, sustained buyer demand, and
-- premium above asking price and historical sold price indicates that 
-- current market conditions in Sacramento may be favorable for sellers.
-- =======================================================================


-- =======================================================================
-- Practice with subqueries and common table expressions (CTEs)
-- =======================================================================

-- Listings priced above the overall average
SELECT L_DisplayId, L_Address, L_City, L_SystemPrice
FROM rets_property
WHERE L_SystemPrice > (
	SELECT AVG(L_SystemPrice)
	FROM rets_property
);

-- Listings priced above their city average
WITH city_avg AS (
    SELECT L_City, ROUND(AVG(L_SystemPrice),0) AS avg_price
	FROM rets_property
	WHERE L_City IS NOT NULL
	GROUP BY L_City
)
SELECT p.L_DisplayId, p.L_Address, p.L_City, p.L_SystemPrice, c.avg_price
FROM rets_property p
LEFT JOIN city_avg c ON p.L_City = c.L_City
WHERE p.L_SystemPrice > c.avg_price;

-- Sale-to-list price ratio by city
SELECT City, 
	   ROUND(AVG(ListPrice),0) AS avg_list_price, 
	   ROUND(AVG(ClosePrice),0) AS avg_close_price, 
	   ROUND(AVG(ClosePrice / ListPrice),2) AS avg_price_ratio 
FROM california_sold
WHERE ListPrice > 0 AND ClosePrice > 0
GROUP BY City
HAVING COUNT(*) > 10 AND avg_price_ratio > 1;

-- Compare active city average price to historical city average price
-- Active listings in Val Verde, Hinkley, Sun Village and a few other cities are priced significantly above historical norms
WITH historical_avg AS (
	SELECT City, ROUND(AVG(ClosePrice),0) AS avg_price
	FROM california_sold
	GROUP BY City
	HAVING COUNT(*) > 10
)
SELECT p.L_City,
	   ROUND(AVG(p.L_SystemPrice),0) AS avg_active_price, 
	   h.avg_price AS avg_historical_price, 
	   ROUND(AVG((p.L_SystemPrice - h.avg_price) / h.avg_price) * 100) AS perc_diff_from_historical
FROM rets_property p
INNER JOIN historical_avg h ON p.L_City = h.City
GROUP BY p.L_City
ORDER BY perc_diff_from_historical DESC;

-- Seasonal trends in housing volume and pricing
-- List and sold volumes tend to be higher in the first half of the year; listings tend to be sold at a higher price in April
WITH sold_trends AS (
	SELECT YEAR(CloseDate) AS close_year, MONTH(CloseDate) AS close_month, 
           COUNT(*) AS sold_volume, ROUND(AVG(ClosePrice),0) AS avg_sold_price
	FROM california_sold
	GROUP BY close_year, close_month
	ORDER BY close_year, close_month
)
SELECT s.close_year AS year, s.close_month AS month, 
       ROUND(AVG(l.ListPrice),0) AS avg_list_price, s.avg_sold_price,
       COUNT(DISTINCT l.ListingKey) AS list_volume, s.sold_volume
FROM california_sold l
INNER JOIN sold_trends s ON YEAR(l.ListingContractDate) = s.close_year AND MONTH(l.ListingContractDate) = s.close_month
GROUP BY year, month
ORDER BY year, month;

-- How discount from list price historically varied by bedroom count
-- It seems that as the number of bedrooms increases, the discount also increases (in the sense that listings are sold from above to below asking price)
SELECT BedroomsTotal AS beds, 
	   ROUND(AVG(ListPrice),0) AS avg_list_price, 
	   ROUND(AVG(ClosePrice),0) AS avg_close_price,
	   ROUND(AVG(1 - ClosePrice / ListPrice) * 100, 0) AS discount
FROM california_sold
WHERE ListPrice > 0 AND ClosePrice > 0
GROUP BY beds
ORDER BY beds;

-- Cities where home typically sell within 2% of asking price
WITH city_perc_diff AS (
	SELECT City, 
		   ROUND(AVG(ListPrice),0) AS avg_list_price,
		   ROUND(AVG(ClosePrice),0) AS avg_close_price,
		   ROUND(AVG(1 - ClosePrice / ListPrice) * 100, 0) AS perc_diff
	FROM california_sold
	GROUP BY City
)
SELECT City, perc_diff
FROM city_perc_diff
WHERE perc_diff BETWEEN -2 and 2;

-- =======================================================================
-- Business scenario: the executive team wants to know whether now is a
-- good time for sellers to list homes in Sacramento
-- =======================================================================

-- (i) Whether homes in Sacramento tend to sell above or below their asking prices, and by what margin
SELECT ROUND(AVG(ListPrice),0) AS avg_list_price, 
	   ROUND(AVG(ClosePrice),0) AS avg_close_price, 
	   AVG(ClosePrice / ListPrice) AS avg_price_ratio, 
	   AVG(ClosePrice / ListPrice - 1) * 100 AS perc_diff
FROM california_sold
WHERE City = 'Sacramento' AND ListPrice > 0 AND ClosePrice > 0;

-- (ii) Seasonal patterns in inventory size
SELECT YEAR(ListingContractDate) AS list_year, MONTH(ListingContractDate) AS list_month, 
	   COUNT(DISTINCT ListingKey) AS inventory_size
FROM california_sold
WHERE City = 'Sacramento'
GROUP BY list_year, list_month;

WITH sold_trends AS (
	SELECT YEAR(CloseDate) AS close_year, MONTH(CloseDate) AS close_month, 
	   	   COUNT(DISTINCT ListingKey) AS sold_volume
	FROM california_sold
	WHERE City = 'Sacramento'
	GROUP BY close_year, close_month
)
SELECT s.close_year AS year, s.close_month AS month, 
	   COUNT(DISTINCT l.ListingKey) AS list_volume, s.sold_volume
FROM california_sold l
INNER JOIN sold_trends s ON YEAR(l.ListingContractDate) = s.close_year AND MONTH(l.ListingContractDate) = s.close_month
WHERE l.City = 'Sacramento'
GROUP BY year, month;

-- (iii) Whether homes in Sacramento are priced higher than historical sold prices
WITH sold_avg AS (
	SELECT City, ROUND(AVG(ClosePrice),0) AS avg_sold_price
	FROM california_sold
	WHERE ClosePrice > 0
	GROUP BY City
)
SELECT p.L_City, 
	   AVG(CASE WHEN p.L_SystemPrice > s.avg_sold_price THEN 1 ELSE 0 END) AS perc_above_historical_avg, 
	   ROUND(AVG((p.L_SystemPrice - s.avg_sold_price) / s.avg_sold_price) * 100, 2) AS perc_diff_from_historical_avg
FROM rets_property p
LEFT JOIN sold_avg s On p.L_City = s.City
GROUP BY p.L_City HAVING p.L_City = 'Sacramento';