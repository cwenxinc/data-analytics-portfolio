-- =======================================================================
-- This script integrates all three data tables using joins, CTEs, window 
-- functions, and aggregations to produce an executive summary table for 
-- investors. 

-- The table reports active listings, average listing price, average 
-- historical sale price, sale-to-list ratio, and a market classification 
-- (seller's, buyer's, or balanced) for each major California city.
-- =======================================================================


-- =======================================================================
-- Part 1: Setup and clarifications
-- =======================================================================

-- This analysis examines the following California cities selected for their large populations, economic significance, and broad geographic representation:
-- 	   Southern California: Los Angeles, San Diego, Anaheim, Irvine
--     Bay Area: San Francisco, San Jose, Oakland
--     Central Valley & Inland California: Sacramento, Fresno, Bakersfield, Riverside

-- Market competitiveness is multifaceted, so we construct a composite competitiveness score for each city rather than relying on a single metric.
-- The score combines four weighted dimensions:
--     1. Inventory tightness (30%) – measured by months of inventory
--     2. Sales pace (30%) – measured by median days on market
--     3. Pricing power (30%) – measured by the average sale-to-list ratio
--     4. Open house activity (10%) – measured by the percentage of active listings with an open house
-- Open house activity is assigned less weight because it reflects seller marketing strategies as much as buyer demand. 
-- The remaining three dimensions receive equal weights, as there is no strong evidence that inventory, sales speed, or pricing power should dominate the overall competitiveness score.

-- Since the dimensions have different units, they are standardized across cities using z-scores before weighting. 
-- Because lower median days on market, months of inventory, and open house activity indicate greater competitiveness, their z-scores are reversed so higher values consistently represent more competitive markets. 
-- NOTE: Low open house activity may indicate that homes sell quickly and sellers rely less on open houses to attract buyers, suggesting a more competitive market

-- Cities are classified using standardized score thresholds: 
--     Score > 0.5: competitive market
--     -0.5 <= Score <= 0.5: balanced market
--     Score < -0.5: buyer opportunity
-- NOTE: Competitiveness is measured relative to the entire California market

-- =======================================================================
-- Part 2.1: Compute the raw dimensions for each city 
-- =======================================================================

-- Since many metrics share common calculations, the analysis is organized as a data pipeline that builds reusable intermediate tables to support downstream calculations.
-- Specifically, temporary tables are used to store intermediate results for downstream metrics. They are preferred over views because they store results rather than the query logic and exist only within the current session.

-- NOTE: Intermediate results are not rounded to preserve precision during z-score standardization

-- Total active listings and average list price by city
CREATE TEMPORARY TABLE listings AS
SELECT L_City, 
       COUNT(Distinct L_DisplayId) AS active_listings,
       AVG(L_SystemPrice) AS avg_list_price
FROM rets_property
GROUP BY L_City HAVING L_City IS NOT NULL; -- data quality issue noted from schema exploration

-- Average historical sale price and sale-to-list ratio by city
CREATE TEMPORARY TABLE sales_pricing AS
SELECT City, 
	   AVG(ClosePrice) AS avg_sale_price, 
	   AVG(ClosePrice / ListPrice) AS avg_price_ratio
FROM california_sold
WHERE ListPrice > 0 AND ClosePrice > 0 -- data quality issue noted from schema exploration
GROUP BY City;

-- Median DOM by city
CREATE TEMPORARY TABLE sales_pace AS
WITH dom_quartiles AS (
	SELECT ListingKey, 
		   City, 
		   DaysOnMarket,
		   NTILE(4) OVER (PARTITION BY City ORDER BY DaysOnMarket) AS dom_quartile
	FROM california_sold
	WHERE DaysOnMarket >= 0 -- data quality issue noted from schema exploration
)
SELECT City, 
	   MAX(DaysOnMarket) AS median_dom
FROM dom_quartiles
GROUP BY City, dom_quartile HAVING dom_quartile = 2;

-- Months of inventory by city
CREATE TEMPORARY TABLE inventory_tightness AS
WITH monthly_sales AS (
	SELECT City, 
		   DATE_FORMAT(CloseDate, '%Y-%m') AS sale_month,
		   COUNT(DISTINCT ListingKey) AS sales
	FROM california_sold
	GROUP BY City, sale_month
),
avg_monthly_sales AS (
	SELECT City, 
		   AVG(sales) AS avg_sales
	FROM monthly_sales
	GROUP BY City
)
SELECT l.L_City, 
	   l.active_listings, 
	   l.avg_list_price,  
	   l.active_listings / s.avg_sales AS months_of_inventory
FROM listings l
INNER JOIN avg_monthly_sales s ON l.L_City = s.City;

-- Percentage of active listings without an open house
CREATE TEMPORARY TABLE openhouse_percentage AS
WITH openhouse_activity AS (
	SELECT p.L_City, 
	   	   COUNT(DISTINCT p.L_DisplayId) AS total_listings, 
	       SUM(CASE WHEN o.L_DisplayId IS NOT NULL THEN 1 ELSE 0 END) AS listings_with_openhouse
	FROM rets_property p
	LEFT JOIN rets_openhouse o ON p.L_DisplayId = o.L_DisplayId
	GROUP BY p.L_City HAVING p.L_City IS NOT NULL -- data quality issue noted from schema exploration
)
SELECT L_City,
	   (listings_with_openhouse / total_listings) * 100 AS perc_with_openhouse
FROM openhouse_activity;

CREATE TEMPORARY TABLE summary_raw AS
SELECT i.L_City, 
	   i.active_listings,
	   i.avg_list_price,
	   s_price.avg_sale_price, 
	   s_price.avg_price_ratio, 
	   i.months_of_inventory AS inventory_tightness, 
	   s_pace.median_dom AS sales_pace, 
	   s_price.avg_price_ratio AS pricing_power, 
	   o.perc_with_openhouse AS openhouse_activity
FROM inventory_tightness i
INNER JOIN sales_pricing s_price ON i.L_City = s_price.City
INNER JOIN sales_pace s_pace ON i.L_City = s_pace.City
INNER JOIN openhouse_percentage o ON i.L_City = o.L_City;

-- =======================================================================
-- Part 2.2: Standardize the dimensions using z-scores
-- =======================================================================

-- Convert dimensions into z-scores
CREATE TEMPORARY TABLE summary_z AS
SELECT L_City AS city, 
	   active_listings,
	   avg_list_price, 
	   avg_sale_price, 
	   avg_price_ratio,
	   (inventory_tightness - AVG(inventory_tightness) OVER()) / STDDEV(inventory_tightness) OVER() AS inventory_tightness_z,
	   (sales_pace - AVG(sales_pace) OVER()) / STDDEV(sales_pace) OVER() AS sales_pace_z,
	   (pricing_power - AVG(pricing_power) OVER()) / STDDEV(pricing_power) OVER() AS pricing_power_z,
	   (openhouse_activity - AVG(openhouse_activity) OVER()) / STDDEV(openhouse_activity) OVER() AS openhouse_activity_z
FROM summary_raw;

-- =======================================================================
-- Part 2.3: Compose the competitiveness scores and create market labels
-- =======================================================================

-- Construct the scores using the weighting scheme outlined in part 1
CREATE TEMPORARY TABLE summary_full AS
WITH scores AS (
	   SELECT *, 
	          0.3 * (inventory_tightness_z * -1) + 
	          0.3 * (sales_pace_z * -1) + 
	          0.3 * pricing_power_z + 
	          0.1 * (openhouse_activity_z * -1) AS competitiveness_score
	FROM summary_z
) -- Then classify each city as competitive market, buyer opportunity, or balanced market using the thresholds described in part 1
SELECT *,
	   CASE
	   	   WHEN competitiveness_score > 0.5 THEN 'Competitive Market'
	   	   WHEN competitiveness_score < -0.5 THEN 'Buyer Opportunity'
	   	   ELSE 'Balanced Market'
	   END as market_type
FROM scores;

-- =======================================================================
-- Part 3: Executive summary
-- =======================================================================

-- Final summary table reporting key market metrics for 10 major California cities
SELECT city AS City, 
       active_listings AS 'Active Listings', 
       ROUND(avg_list_price,0) AS 'Average Active Price', 
       ROUND(avg_sale_price,0) As 'Average Historical Sale Price',
       ROUND(avg_price_ratio,2) AS 'Average Historical Sale-to-List Ratio',
       market_type AS 'Market Classification'
FROM summary_full
WHERE city IN ('Los Angeles', 'San Diego', 'Anaheim', 'Irvine', 
			   'San Francisco', 'San Jose', 'Oakland', 
			   'Sacramento', 'Fresno', 'Bakersfield', 'Riverside');