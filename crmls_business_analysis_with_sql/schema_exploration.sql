-- =======================================================================
-- This script explores the structure of the database and performs data
-- quality checks to identify NULLs, duplicates, outliers, and 
-- inconsistencies.
-- We keep the following data issues in mind:
-- 1. 30776 listings in rets_property do not have open house records.
-- 2. california_sold contains a more comprehensive list of cities than
--    rets_property.
-- 3. rets_property has null values across L_Keyword2 (bedrooms), 
--    LM_Dec_3 (bathrooms), LM_int2_3 (square footage), and L_City.
-- 4. Numeric columns often contain outliers. This applies to both 
--    rets_property and california_sold.
-- =======================================================================

-- =======================================================================
-- Part 1: List the tables and their metadata (row counts and sizes in mb)
-- =======================================================================
SELECT TABLE_NAME, TABLE_ROWS, (DATA_LENGTH / 1024 / 1024) AS size_mb
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'rets'
ORDER BY size_mb DESC;

-- =======================================================================
-- Part 2.1: Explore the structure of rets_property
-- =======================================================================
-- NOTE: All columns except for identifier and timestamps can contain nulls
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'rets' AND TABLE_NAME = 'rets_property';

-- Profile column quality
-- (i) Check null counts across key columns
-- NOTE: 101 missing bedroom count, 17 missing bathroom count, 76 missing square footage, 72 missing city
SELECT SUM(CASE WHEN L_DisplayId IS NULL THEN 1 ELSE 0 END) AS id_nulls,
	   SUM(CASE WHEN L_SystemPrice IS NULL THEN 1 ELSE 0 END) AS price_nulls,
	   SUM(CASE WHEN L_Status IS NULL THEN 1 ELSE 0 END) AS status_nulls,
	   SUM(CASE WHEN ListingContractDate IS NULL THEN 1 ELSE 0 END) AS date_nulls,
	   SUM(CASE WHEN L_Keyword2 IS NULL THEN 1 ELSE 0 END) AS bedroom_nulls,
	   SUM(CASE WHEN LM_Dec_3 IS NULL THEN 1 ELSE 0 END) AS bathroom_nulls,
	   SUM(CASE WHEN LM_int2_3 IS NULL THEN 1 ELSE 0 END) AS sqft_nulls, 
	   SUM(CASE WHEN L_City IS NULL THEN 1 ELSE 0 END) AS city_nulls
FROM rets_property;

-- (ii) See if the table only contains active or pending properties (YES)
SELECT DISTINCT L_Status
FROM rets_property;

-- (iii) Validate the distributions of numeric columns
-- NOTE: Price ranges from 795-170000000, bedrooms from 0-71, bathrooms from 0-67, square footage from 0-50000
-- TODO: Filter out properties with 0 square footage, 0 bedrooms, or unusually high price/bedrooms/bathrooms/square footage 
SELECT MIN(L_SystemPrice) AS price_min, MAX(L_SystemPrice) AS price_max,
       MIN(L_Keyword2) AS bedroom_min, MAX(L_Keyword2) AS bedroom_max,
       MIN(LM_Dec_3) AS bathroom_min, MAX(LM_Dec_3) AS bathrooms_max,
       MIN(LM_Int2_3) AS sqft_min, MAX(LM_Int2_3) AS sqft_max
FROM rets_property;

-- Remove duplicates
-- (i) See if duplicates exist (NONE)
SELECT COUNT(L_DisplayId) AS total_count, COUNT(DISTINCT L_DisplayId) AS distinct_count
FROM rets_property;

-- (ii) If duplicates exist, see which IDs appear more than once
SELECT L_DisplayId, COUNT(*) AS occurrences
FROM rets_property
GROUP BY L_DisplayId
HAVING occurrences > 1;

-- =======================================================================
-- Part 2.2: Explore the structure of rets_openhouse
-- =======================================================================
-- NOTE: API openhouse start date and end date can be null
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'rets' AND TABLE_NAME = 'rets_openhouse';

-- Profile column quality
-- (i) Check if end time is ever before start time
-- NOTE: 21
SELECT SUM(CASE WHEN OH_EndTime < OH_StartTime THEN 1 ELSE 0 END) AS invalid_time
FROM rets_openhouse;

-- (ii) Check if end date is ever before start date (NONE)
SELECT SUM(CASE WHEN OH_EndDate < OH_StartDate THEN 1 ELSE 0 END) AS invalid_date
FROM rets_openhouse;

-- Remove duplicates
-- NOTE: None exist, but note that a property can have multiple open house events and thus multiple entries
SELECT COUNT(L_DisplayId) AS total_count, COUNT(DISTINCT L_DisplayId) AS distinct_count
FROM rets_openhouse;

-- =======================================================================
-- Part 2.3: Explore the structure of california_sold
-- =======================================================================
-- NOTE: All columns can contain nulls
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'rets' AND TABLE_NAME = 'california_sold';

-- Profile column quality
-- (i) Check null counts across key columns (ALL 0)
SELECT SUM(CASE WHEN ListingKey IS NULL THEN 1 ELSE 0 END) AS id_nulls,
       SUM(CASE WHEN ListPrice IS NULL THEN 1 ELSE 0 END) AS listprice_nulls,
       SUM(CASE WHEN ClosePrice IS NULL THEN 1 ELSE 0 END) AS closeprice_nulls,
       SUM(CASE WHEN DaysOnMarket IS NULL THEN 1 ELSE 0 END) AS dom_nulls,
       SUM(CASE WHEN ListingContractDate IS NULL THEN 1 ELSE 0 END) AS listdate_nulls,
       SUM(CASE WHEN PurchaseContractDate IS NULL THEN 1 ELSE 0 END) AS purchasedate_nulls,
       SUM(CASE WHEN CloseDate IS NULL THEN 1 ELSE 0 END) AS closedate_nulls,
       SUM(CASE WHEN BedroomsTotal IS NULL THEN 1 ELSE 0 END) AS bedrooms_nulls,
       SUM(CASE WHEN BathroomsTotalInteger IS NULL THEN 1 ELSE 0 END) AS bathrooms_nulls,
       SUM(CASE WHEN LivingArea IS NULL THEN 1 ELSE 0 END) AS livingarea_nulls,
       SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS city_nulls
FROM california_sold;

-- (ii) Validate the distribution of numeric columns
-- NOTE: 0 list price, 0 close price, -84-12430 DOM, 0-112 beds, 0-153 baths, 0-17021321 square footage
-- TODO: Filter out properties with 0 list price/close price, negative DOMs, 0 beds, 0 square footage, or unusually high DOM/beds/baths/square footage
SELECT MIN(ListPrice) AS listprice_min, MAX(ListPrice) AS listprice_max,
       MIN(ClosePrice) AS closeprice_min, MAX(ClosePrice) AS closeprice_max,
       MIN(DaysOnMarket) AS dom_min, MAX(DaysOnMarket) AS dom_max,
       MIN(BedroomsTotal) AS beds_min, MAX(BedroomsTotal) AS beds_max,
       MIN(BathroomsTotalInteger) AS baths_min, MAX(BathroomsTotalInteger) AS baths_max,
       MIN(LivingArea) AS livingarea_min, MAX(LivingArea) AS livingarea_max
FROM california_sold;

-- (iii) Validate date columns
-- NOTE: 3462 listed after contract, 147 contract after close, 25 listed after close
-- TODO: Filter out properties with dubious timeline
SELECT SUM(CASE WHEN ListingContractDate > PurchaseContractDate THEN 1 ELSE 0 END) AS list_after_contract,
       SUM(CASE WHEN PurchaseContractDate > CloseDate THEN 1 ELSE 0 END) AS contract_after_close,
       SUM(CASE WHEN ListingContractDate > CloseDate THEN 1 ELSE 0 END) AS list_after_close
FROM california_sold;

-- Remove duplicates (NONE)
SELECT COUNT(*) AS total_count, COUNT(DISTINCT ListingKey) AS distinct_count
FROM california_sold;

-- =======================================================================
-- Part 3: Understand table relationships with cardinality checks
-- =======================================================================
-- Because rets_property and rets_openhouse both feature active listings, we need to check if their relationship is one-to-one or one-to-many
-- If we have one-to-many relationships, joining the tables would result in multiple joined rows for each key and inflate aggregations like counts

-- NOTE: Previous queries showed that no duplicates exist in either rets_property or rets_openhouse, suggesting one-to-one relationship
-- Verify that each listing only has 1 entry in either table
SELECT COUNT(*) AS total_count, COUNT(DISTINCT L_DisplayId) AS distinct_count, COUNT(*) / COUNT(DISTINCT L_DisplayId) AS avg_rows_per_id
FROM rets_openhouse;
SELECT COUNT(*) AS total_count, COUNT(DISTINCT L_DisplayId) AS distinct_count, COUNT(*) / COUNT(DISTINCT L_DisplayId) AS avg_rows_per_id
FROM rets_property;

-- There are more listings in rets_property than in rets_openhouse
-- Check how many listings do not have a corresponding open house record (30776)
SELECT COUNT(*) AS listings_without_openhouse
FROM rets_property rp -- the overall query is based on the larger table
WHERE NOT EXISTS ( -- this part flips the logic and excludes matches
	SELECT 1 FROM rets_openhouse ro WHERE ro.L_DisplayId = rp.L_DisplayId -- this subquery keeps all matches
);

-- Given that california_sold is historical data, see if City values match the City values in rets_property
-- NOTE: 190 City values in california_sold are not found in rets_property
SELECT COUNT(DISTINCT City) AS no_match
FROM california_sold
WHERE City NOT IN (
	SELECT DISTINCT L_City
	FROM rets_property
	WHERE L_City IS NOT NULL -- recall the 72 nulls in L_City
);

-- Check which City values are not found in rets_property
SELECT DISTINCT City
FROM california_sold
WHERE City NOT IN (
	SELECT DISTINCT L_City
	FROM rets_property
	WHERE L_City IS NOT NULL -- recall the 72 nulls in L_City
);
