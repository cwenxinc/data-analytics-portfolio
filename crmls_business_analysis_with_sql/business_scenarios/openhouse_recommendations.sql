-- =======================================================================
-- This script uses INNER JOIN and LEFT JOIN queries to identify cities 
-- and weekend days that generate the strongest open house engagement, 
-- helping the sales team prioritize where and when to host events.

-- Based on the analysis, we recommend hosting open houses on both 
-- Saturdays and Sundays in Los Angeles and San Diego, and on Saturdays 
-- in San Jose and Palm Desert. These city–day combinations showed both
-- high open house volume and high open house rate among active listings, 
-- suggesting greater buyer engagement.
-- =======================================================================


-- =======================================================================
-- Practice with JOINs
-- =======================================================================

-- Listings with open houses
SELECT rp.L_DisplayId, rp.L_Address, rp.L_City, rp.L_SystemPrice,
	   ro.OpenHouseDate, ro.OH_StartTime, ro.OH_EndTime
FROM rets_property rp
INNER JOIN rets_openhouse ro ON rp.L_DisplayId = ro.L_DisplayId
ORDER BY ro.OpenHouseDate, ro.OH_StartTime;

-- Open houses per listing
SELECT rp.L_DisplayId, COUNT(*) AS num_openhouses
FROM rets_property rp
INNER JOIN rets_openhouse ro ON rp.L_DisplayId = ro.L_DisplayId
GROUP BY rp.L_DisplayId
ORDER BY num_openhouses DESC;

-- Percentage of listings that have open houses scheduled (25%)
SELECT SUM(CASE WHEN ro.OpenHouseDate IS NOT NULL THEN 1 ELSE 0 END) AS num_with_openhouse,
       SUM(CASE WHEN ro.OpenHouseDate IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) AS perc_with_openhouse
FROM rets_property rp
LEFT JOIN rets_openhouse ro ON rp.L_DisplayId = ro.L_DisplayId;
-- Alternative query
SELECT COUNT(DISTINCT rp.L_DisplayId) AS num_listings,
       COUNT(DISTINCT ro.L_DisplayId) AS num_listings_with_openhouse,
       COUNT(DISTINCT ro.L_DisplayId) / COUNT(DISTINCT rp.L_DisplayId) AS perc_with_openhouse
FROM rets_property rp
LEFT JOIN rets_openhouse ro ON rp.L_DisplayId = ro.L_DisplayId;

-- Open house activity by city
-- Los Altos has the highest openhouse percentage, followed by South San Francisco and Anaheim Hills
SELECT rp.L_City,
       COUNT(DISTINCT rp.L_DisplayId) AS num_listings,
       COUNT(DISTINCT ro.L_DisplayId) AS num_listings_with_openhouse,
       COUNT(DISTINCT ro.L_DisplayId) / COUNT(DISTINCT rp.L_DisplayId) AS perc_with_openhouse
FROM rets_property rp
LEFT JOIN rets_openhouse ro ON rp.L_DisplayId = ro.L_DisplayId
GROUP BY rp.L_City
HAVING COUNT(DISTINCT rp.L_DisplayId) >= 10
ORDER BY perc_with_openhouse DESC;

-- Average list price by city for listings with open houses
SELECT rp.L_City, ROUND(AVG(rp.L_SystemPrice),0) AS avg_price, COUNT(DISTINCT rp.L_DisplayId) AS listing_count
FROM rets_property rp
INNER JOIN rets_openhouse ro ON rp.L_DisplayId = ro.L_DisplayId
GROUP BY rp.L_City
ORDER BY avg_price;

-- Most popular open house days
-- Weekend is the most popular: Saturday has the most open houses scheduled, followed by Sunday and Friday
SELECT DAYNAME(OpenHouseDate) AS day_of_week, COUNT(*) AS num_openhouses
FROM rets_openhouse
GROUP BY DAYNAME(OpenHouseDate)
ORDER BY num_openhouses DESC;

-- Do higher-priced listings have more open houses on average?
-- Hard to tell, because each listing has at most one open house scheduled
SELECT rp.L_DisplayId, ROUND(AVG(rp.L_SystemPrice),0) AS list_price, COUNT(ro.OpenHouseDate) AS num_openhouses
FROM rets_property rp
INNER JOIN rets_openhouse ro ON rp.L_DisplayId = ro.L_DisplayId
GROUP BY rp.L_DisplayId
ORDER BY list_price DESC;

-- =======================================================================
-- Business scenario: the sales team plans to host open houses on weekends
-- in cities where open house activity is already high and wants to know
-- which cities and days to target.
-- =======================================================================

-- Restrict to open house records on weekends and identify cities with high open house activity
With total_listings AS (
	SELECT L_City, 
		   COUNT(DISTINCT L_DisplayId) AS listings
	FROM rets_property
	GROUP BY L_City HAVING L_City IS NOT NULL
)
SELECT p.L_City, 
	   DAYNAME(o.OpenHouseDate) AS day_of_week,
	   SUM(CASE WHEN o.L_DisplayId IS NOT NULL THEN 1 ELSE 0 END) AS openhouses,
	   AVG(l.listings) AS total_active_listings,
	   ROUND(SUM(CASE WHEN o.L_DisplayId IS NOT NULL THEN 1 ELSE 0 END) / AVG(l.listings) * 100, 2) AS openhouse_perc_among_all
FROM rets_property p
LEFT JOIN total_listings l ON p.L_City = l.L_City
LEFT JOIN rets_openhouse o ON p.L_DisplayId = o.L_DisplayId
GROUP BY p.L_City, day_of_week
HAVING p.L_City IS NOT NULL AND day_of_week LIKE 'S%'
ORDER BY openhouses DESC, openhouse_perc_among_all DESC;
