-- =======================================================================
-- This script runs queries that utilize SELECT, WHERE, ORDER BY, and 
-- LIMIT to help the sales team identify where the most affordable 
-- properties are.
-- The result varies based on how affordability is defined:
-- Markleeville appears to be the most affordable for home buyers in terms 
-- of average price, average price per sq ft, and average bedroom value, 
-- but Los Angeles has the most listings under the city's average price.
-- =======================================================================

-- =======================================================================
-- Practice with SELECT, WHERE, ORDER BY, LIMIT
-- =======================================================================
-- 3+ bedroom listings under $700k in Los Angeles
SELECT L_DisplayId, L_SystemPrice, L_Keyword2
FROM rets_property
WHERE L_Keyword2 >= 3 AND L_SystemPrice < 700000 AND L_City = 'Los Angeles' 
ORDER BY L_SystemPrice ASC;

-- Listings between $400k and $600k in cities that start with 'San'
SELECT L_DisplayId, L_City, L_SystemPrice
FROM rets_property
WHERE L_SystemPrice BETWEEN 400000 AND 600000
  AND L_City LIKE 'San%'
ORDER BY L_SystemPrice ASC
LIMIT 20;

-- 10 listings with the largest square footage
SELECT L_DisplayId, L_City, L_Address, LM_Int2_3
FROM rets_property
WHERE LM_Int2_3 IS NOT NULL
ORDER BY LM_Int2_3 DESC
LIMIT 10;

-- 10 cheapest listings in Los Angeles
SELECT L_DisplayId, L_Address, L_SystemPrice
FROM rets_property
WHERE L_City = 'Los Angeles'
ORDER BY L_SystemPrice ASC
LIMIT 10;

-- =======================================================================
-- Business scenario: The sales team wants to put together a buyer's guide 
-- to show customers where the most affordable options are
-- =======================================================================
-- The result depends on how the sales team defines 'affordable':
-- (i) If the team defines 'affordable' as low list price
SELECT L_DisplayId, L_City, L_Address, L_SystemPrice
FROM rets_property
ORDER BY L_SystemPrice ASC;

-- (ii) If the team defines 'affordable' as low price per square ft
SELECT L_DisplayId, L_City, L_Address, ROUND(L_SystemPrice / LM_Int2_3, 2) AS price_per_sqft
FROM rets_property
WHERE L_SystemPrice / LM_Int2_3 IS NOT NULL
ORDER BY price_per_sqft ASC;

-- (iii) If the team is looking for cities with the lowest average list price
-- ANSWER: Markleeville, followed by Dorries and Westwood
SELECT L_City, AVG(L_SystemPrice) AS avg_price
FROM rets_property
GROUP BY L_City
HAVING L_City IS NOT NULL
ORDER BY avg_price ASC;

-- (iv) If the team is looking for cities with the lowest average price per square ft
-- ANSWER: Markleeville, followed by Walnut Grove and Ravendale; Westwood falls to the fifth
SELECT L_City, AVG(L_SystemPrice / LM_Int2_3) AS avg_price_per_sqft
FROM rets_property
WHERE L_SystemPrice / LM_Int2_3 IS NOT NULL
GROUP BY L_City
HAVING L_City IS NOT NULL
ORDER BY avg_price_per_sqft ASC;

-- (v) If the team is looking for cities with the most listings under city average
-- ANSWER: Los Angeles (with 2320 listings under average), followed by San Diego and Palm Desert
WITH city_avg AS (
	SELECT L_City, AVG(L_SystemPrice) AS avg_price
	FROM rets_property
	GROUP BY L_City
	HAVING L_City IS NOT NULL
)
SELECT p.L_City, SUM(CASE WHEN p.L_SystemPrice < c.avg_price THEN 1 ELSE 0 END) AS under_avg_count
FROM rets_property p
JOIN city_avg c ON p.L_City = c.L_City
GROUP BY p.L_City
ORDER BY under_avg_count DESC;

-- If the team puts more emphasis on bedroom/bathroom configuration and is looking for cities with the best value per bedroom/bathroom
-- ANSWER: Markleeville, followed by Ravendale and Westwood
SELECT L_City, ROUND(AVG(L_SystemPrice / L_Keyword2), 2) AS avg_bedroom_value
FROM rets_property
WHERE L_SystemPrice / L_Keyword2 IS NOT NULL
GROUP BY L_City
HAVING L_City IS NOT NULL
ORDER BY avg_bedroom_value ASC;
