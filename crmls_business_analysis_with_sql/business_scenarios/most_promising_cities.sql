-- =======================================================================
-- This script runs queries that utilize aggregations and grouping to help
-- the marketing team identify cities with the best opportunity for
-- first-time homebuyers.
-- Since the best opportunity lies in cities shifting toward a buyer's
-- market, we recommend cities from three angles that signal increasing
-- buyer purchasing power:
-- 1. Large inventory size: Los Angeles, San Diego and Palm Desert
-- 2. Low price point: Markleeville, Walnut Grove and Ravendale
-- 3. Long days on market and high seller motivation: California Valley, 
--    Salton City and Summerland
-- =======================================================================


-- =======================================================================
-- Practice aggregations and grouping
-- =======================================================================

-- Supply and pricing by city
SELECT L_City,
	   COUNT(*) AS supply,
	   ROUND(AVG(L_SystemPrice),0) AS avg_list_price, 
	   MIN(L_SystemPrice) AS min_list_price, 
	   MAX(L_SystemPrice) AS max_list_price
FROM rets_property
WHERE L_City IS NOT NULL 
GROUP BY L_City
ORDER BY avg_list_price DESC;

-- Supply and pricing by city (only looking at cities with at least 10 listings)
SELECT L_City,
	   COUNT(*) AS supply,
	   ROUND(AVG(L_SystemPrice),0) AS avg_list_price
FROM rets_property
WHERE L_City IS NOT NULL 
GROUP BY L_City
HAVING supply >= 10
ORDER BY avg_list_price DESC;

-- Cities with the most active inventory (i.e. most supply)
SELECT L_City, COUNT(*) AS supply
FROM rets_property
WHERE L_City IS NOT NULL
GROUP BY L_City
ORDER BY supply DESC;

-- Price per sq ft by city
SELECT L_City,
	   ROUND(AVG(L_SystemPrice),0) AS avg_list_price,
	   ROUND(AVG(LM_Int2_3),0) AS avg_sqft,
	   ROUND(AVG(L_SystemPrice / LM_Int2_3),0) AS avg_price_per_sqft
FROM rets_property
WHERE LM_Int2_3 > 0 AND L_CITY IS NOT NULL -- recall nulls discovered during schema exploration
GROUP BY L_City
ORDER BY avg_price_per_sqft DESC;

-- Pricing by bedroom/bathroom configuration
SELECT L_Keyword2 AS beds, LM_Dec_3 AS baths,
       COUNT(*) AS total_listings, 
       ROUND(AVG(L_SystemPrice),0) AS avg_list_price
FROM rets_property
WHERE L_Keyword2 > 0 AND LM_Dec_3 IS NOT NULL
GROUP BY L_Keyword2, LM_Dec_3
HAVING total_listings >= 10;

-- =======================================================================
-- Business scenario: The marketing team is launching a new ad campaign
-- and wants to focus on the three cities that represent the best 
-- opportunity for first-time buyers.
-- =======================================================================

-- Cities shifting toward a buyer's market present favorable opportunities for homebuyers. 
-- These markets may have higher housing inventory, lower price point, or listings with longer days on market, giving buyers greater negotiating power and reducing the likelihood of competitive bidding wars.

-- (i) Los Angeles, San Diego and Palm Desert offer the best opportunity in terms of inventory size
SELECT L_City, COUNT(*) AS inventory_size
FROM rets_property
WHERE L_City IS NOT NULL
GROUP BY L_City
ORDER BY inventory_size DESC
LIMIT 3;

-- (ii) Markleeville, Walnut Grove, and Ravendale offer the best opportunity in terms of price per sq ft
SELECT L_City, ROUND(AVG(L_SystemPrice / LM_Int2_3),0) AS avg_price_per_sqft
FROM rets_property
WHERE L_City IS NOT NULL AND LM_Int2_3 > 0
GROUP BY L_City
ORDER BY avg_price_per_sqft ASC
LIMIT 3;

-- (iii) California Valley, Salton City, and Summerland offer the best opportunity in terms of days on market
SELECT L_City, ROUND(AVG(DaysOnMarket),0) AS avg_dom
FROM rets_property
GROUP BY L_City
ORDER BY avg_dom DESC
LIMIT 3;


