-- =======================================================================
-- This script uses CTEs and window functions to identify the most 
-- competitive housing markets by evaluating pricing power, inventory 
-- tightness, and sales speed.

-- The analysis reveals that:
-- 1. Seller leverage is strongest in Antelope, Mission Hills, Orange Cove, 
--    Otay Mesa, and Stevinson, where all homes sold above asking price 
--    with 2%–9% average premiums.
-- 2. Supply is most constrained in Montrose, Pacheco, California Valley, 
--    Crockett, and Piedmont, where inventory falls below one month of 
--    historical sales demand, while Salton City, Westwood Century City, 
--    and many additional cities show stagnant or declining new listing 
--    growth.
-- 3. Competition is most intense in Hughson, Mira Mesa, Wasco, Clairemont 
--    Mesa, Imperial, and Planada, where at least half of homes sell within 
--    seven days of listing.

-- Together, these indicators identify markets where demand consistently 
-- outpaces available supply, creating conditions favorable for sellers 
-- and investors.
-- =======================================================================


-- =======================================================================
-- Practice with window functions (rankings and PARTITION BY)
-- =======================================================================

-- Rank the cities by their average list price
SELECT L_City,
	   ROUND(AVG(L_SystemPrice),0) AS avg_price,
	   RANK() OVER (
	        ORDER BY AVG(L_SystemPrice) DESC
	   ) AS price_rank
FROM rets_property
WHERE L_City IS NOT NULL
GROUP BY L_City;

-- Rank the cities by their price variability (e.g., standard deviation in list price)
SELECT L_City,
	   STDDEV(L_SystemPrice) AS sd_price,
	   RANK() OVER (
	        ORDER BY STDDEV(L_SystemPrice)
	   ) AS sd_rank
FROM rets_property
WHERE L_City IS NOT NULL
GROUP BY L_City
ORDER BY sd_rank; -- cities at the top have the most consistent pricing

-- Rank the listings by their prices within the city
SELECT L_DisplayId, L_Address, L_City, L_SystemPrice, -- keeps individual listings
	   AVG(L_SystemPrice) OVER (PARTITION BY L_City) AS city_avg, -- includes aggregated context
	   L_SystemPrice - AVG(L_SystemPrice) OVER (PARTITION BY L_City) AS diff_from_city_avg, 
	   RANK() OVER (PARTITION BY L_City ORDER BY L_SystemPrice DESC) AS rank_in_city
FROM rets_property
WHERE L_City IS NOT NULL;

-- Price outliers within each city
-- (i) Listings that are priced over 2 standard deviations from their city average
WITH city_statistics AS (
	SELECT L_City, 
		   AVG(L_SystemPrice) as city_avg, 
		   STDDEV(L_SystemPrice) AS city_sd
	FROM rets_property
	WHERE L_City IS NOT NULL
	GROUP BY L_City HAVING COUNT(*) >= 30 -- needs n=30 for statistical calculations to be robust
)
SELECT p.L_DisplayId, p.L_Address, p.L_City, 
	   p.L_SystemPrice, ROUND(s.city_avg,0) AS city_avg, ROUND(s.city_sd,0) AS city_sd
FROM rets_property p
LEFT JOIN city_statistics s ON p.L_City = s.L_City
WHERE p.L_City IS NOT NULL AND 
	  p.L_SystemPrice NOT BETWEEN s.city_avg - 2 * s.city_sd AND s.city_avg + 2 * s.city_sd;
-- (ii) Listings that are priced within the top or bottom 10% in their city
WITH percentiles AS (
	SELECT L_DisplayId, L_Address, L_City, L_SystemPrice,
		   PERCENT_RANK() OVER (PARTITION BY L_City ORDER BY L_SystemPrice) AS price_percentile, 
		   COUNT(*) OVER (PARTITION BY L_City) AS inventory_size
	FROM rets_property
	WHERE L_City IS NOT NULL
)
SELECT L_DisplayId, L_City, L_SystemPrice, price_percentile, inventory_size
FROM percentiles
WHERE (price_percentile < 0.1 OR price_percentile > 0.9)
  AND inventory_size > 10; -- focuses on cities with relatively large housing inventory

-- Sold price quartiles
WITH quartiles AS (
	SELECT ClosePrice, 
		   NTILE(4) OVER (ORDER BY ClosePrice) AS price_quartile
	FROM california_sold
)
SELECT price_quartile, 
	   MIN(ClosePrice) AS min_price, 
	   MAX(ClosePrice) AS max_price,
	   ROUND(AVG(ClosePrice),0) AS avg_price
FROM quartiles
GROUP BY price_quartile;

-- Monthly running totals of housing inventory
-- (i) Overall
WITH monthly_totals AS (
	SELECT DATE_FORMAT(ListingContractDate, '%Y-%m') AS list_month, 
	   	   COUNT(*) AS new_listings
	FROM rets_property
	GROUP BY list_month
	ORDER BY list_month
)
SELECT list_month, new_listings, 
	   SUM(new_listings) OVER (ORDER BY list_month) AS running_total -- NOTE: including ROWS UNBOUNDED PRECEDING is preferred, as it sums one row at a time and accounts for possible duplicates in the ORDER BY column
FROM monthly_totals;
-- (ii) Per city
WITH monthly_totals AS (
	SELECT L_City, 
		   DATE_FORMAT(ListingContractDate, '%Y-%m') AS list_month,
		   COUNT(*) AS new_listings
	FROM rets_property
	WHERE L_City IS NOT NULL
	GROUP BY L_City, list_month
)
SELECT L_City, list_month, new_listings,
	   SUM(new_listings) OVER (
	   		PARTITION BY L_City 
	   		ORDER BY list_month 
	   		ROWS UNBOUNDED PRECEDING
	   ) AS running_total
FROM monthly_totals
ORDER BY L_City, list_month;

-- Single most expensive listing per city
WITH price_rankings AS (
	SELECT L_DisplayId, L_City, L_Address, L_SystemPrice, 
		   RANK() OVER (PARTITION BY L_City ORDER BY L_SystemPrice DESC) AS rank_in_city
	FROM rets_property
	WHERE L_City IS NOT NULL
)
SELECT *
FROM price_rankings
WHERE rank_in_city = 1; -- NOTE: a CTE wrapper is required to separate the window functions before filtering, because window functions run *after* the WHERE clause

-- =======================================================================
-- Business scenario: The CEO wants to identify competitive housing 
-- markets to guide investment decisions.
-- =======================================================================

-- Competitive markets give sellers leverage and reflect in sale-to-list pricing, tight inventory, and short transaction cycle
-- The following queries identify cities that excel in each of these aspects:

-- 1. Pricing power
-- (i) Find cities with a high share of homes sold above asking price
SELECT City, ROUND(AVG(ClosePrice > ListPrice) * 100, 2) AS perc_sold_above_asking
FROM california_sold
WHERE ListPrice > 0 AND ClosePrice > 0
GROUP BY City HAVING COUNT(*) > 1 -- focuses on cities with at least two sales
ORDER BY perc_sold_above_asking DESC;
-- (ii) Among cities where homes typically sell above asking, find those with the largest sale-to-list price premiums
WITH price_ratios AS (
	SELECT City, AVG(ClosePrice / ListPrice) AS avg_price_ratio
	FROM california_sold
	WHERE ListPrice > 0 AND ClosePrice > 0
	GROUP BY City HAVING COUNT(*) > 1 -- focuses on cities with at least two sales
)
SELECT City, ROUND(AVG((ClosePrice - ListPrice) / ListPrice),2) AS avg_premium
FROM california_sold
WHERE ListPrice > 0 AND ClosePrice > 0
	AND City IN (
		SELECT City
		FROM price_ratios
		WHERE avg_price_ratio > 1
	)
GROUP BY City -- HAVING City IN ('Antelope', 'Mission Hills', 'Orange Cove', 'Otay Mesa', 'Stevinson')
ORDER BY avg_premium DESC;

-- 2. Inventory tightness
-- (i) Find cities with low new listing growth
WITH monthly_new_listings AS (
	SELECT L_City, 
	   	   DATE_FORMAT(ListingContractDate, '%Y-%m') AS list_month, 
	       COUNT(DISTINCT L_DisplayId) AS new_listings
	FROM rets_property
	WHERE L_City IS NOT NULL
	GROUP BY L_City, list_month
),
monthly_growth AS (
	SELECT L_City,
	       list_month,
	       (new_listings - LAG(new_listings) OVER (PARTITION BY L_City ORDER BY list_month)) / 
	       LAG(new_listings) OVER (PARTITION BY L_City ORDER BY list_month) AS growth_rate
	FROM monthly_new_listings
)
SELECT L_City, 
	   ROUND(AVG(growth_rate),2) AS avg_monthly_growth
FROM monthly_growth
GROUP BY L_City HAVING avg_monthly_growth IS NOT NULL -- focuses on cities with at least two months of listing timeframe
ORDER BY avg_monthly_growth;
-- (ii) Find cities with low inventory (i.e. low months of inventory or high sales-to-active-listings ratio)
WITH monthly_sales AS (
	SELECT City, 
		   DATE_FORMAT(CloseDate, '%Y-%m') AS sale_month, 
		   COUNT(DISTINCT ListingKey) AS num_sales
	FROM california_sold
	GROUP BY City, sale_month HAVING COUNT(*) > 1
),
avg_sales AS ( -- computes monthly closed sales from historical sales
	SELECT City, ROUND(AVG(num_sales),0) AS avg_monthly_sales
	FROM monthly_sales
	GROUP BY City
),
active_inventory AS ( -- computes inventory from active listings
	SELECT L_City, COUNT(DISTINCT L_DisplayId) AS num_active
	FROM rets_property
	GROUP BY L_City HAVING L_City IS NOT NULL
)
SELECT a.L_City, a.num_active, s.avg_monthly_sales, 
	   ROUND(s.avg_monthly_sales / a.num_active,2) AS sales_to_active_listings_ratio,
	   ROUND(a.num_active / s.avg_monthly_sales,2) AS months_of_inventory
FROM active_inventory a
INNER JOIN avg_sales s ON a.L_City = s.City -- recall that historical data encompasses more cities than active listing data
ORDER BY months_of_inventory;

-- 3. Short sales cycle (i.e. bidding wars)
-- (i) Find cities with short days on market
WITH dates_converted AS (
	SELECT ListingKey,
		   City, 
		   DaysOnMarket, 
		   CAST(ListingContractDate AS DATE) AS list_date, 
		   CAST(PurchaseContractDate AS DATE) AS purchase_date
	FROM california_sold
)
SELECT City, 
	   ROUND(AVG(DaysOnMarket),0) AS avg_dom, 
	   ROUND(AVG(DATEDIFF(purchase_date, list_date)),0) AS listing_to_contract_days -- included this additional metric because closing may occur weeks after contract 
FROM dates_converted
WHERE list_date IS NOT NULL AND purchase_date IS NOT NULL AND list_date < purchase_date
GROUP BY City HAVING COUNT(*) > 1
ORDER BY avg_dom, listing_to_contract_days;
-- Since DOM tends to be right-skewed, compute the median DOM for each city instead
WITH percentiles AS (
	SELECT ListingKey, 
		   City, 
		   DaysOnMarket, 
		   NTILE(4) OVER (PARTITION BY City ORDER BY DaysOnMarket) AS dom_quartile
	FROM california_sold
)
SELECT City, MAX(DaysOnMarket) AS median_dom
FROM percentiles
GROUP BY City, dom_quartile HAVING dom_quartile = 2
ORDER BY median_dom;
-- (ii) Find cities with a large share of homes sold within 7 days (DOM <= 7 indicates a highly competitive market)
SELECT City, 
	   ROUND(AVG(DaysOnMarket <= 7) * 100,2) AS perc_sold_within_7d
FROM california_sold
WHERE DaysOnMarket >= 0
GROUP BY City HAVING COUNT(*) > 1 -- AND City IN ('Hughson', 'Mira Mesa', 'Wasco', 'Clairemont Mesa', 'Imperial', 'Planada')
ORDER BY perc_sold_within_7d DESC;
