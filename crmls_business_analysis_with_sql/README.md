# CRMLS Business Analysis
This project analyzes California MLS real estate data across three ***MySQL** tables using ***DBeaver** to answer key business questions about the housing market.

## Key Findings

## Database
The database consists of three tables:
- rets_property: active listings
- rets_openhouse: open house schedules and details, linked to rets_property via the unique listing identifier
- california_sold: historical sales

## Tools Used
- MySQL (via Docker)
- DBeaver (Community edition)

## Directory Structure
Each SQL file applies specific SQL concepts to a practical business scenario. The final SQL script produces an executive summary of market conditions across California cities, including a composite competitiveness score and market classification (competitive, balanced, or buyer opportunity) for each city. Each file begins with a summary of the business question and key findings.
```
schema_exploration.sql                    - Schema discovery and data quality checks
business_scenarios
├── most_affordable_cities.sql            - SELECT, WHERE, ORDER BY, and LIMIT
├── most_competitive_cities.sql           - Window functions with CTE wrappers
├── most_promising_cities.sql             - Aggregations and GROUP BY
├── openhouse_recommendations.sql         - JOINs across two tables
└── sacramento_market_conditions.sql      - Subqueries and CTEs
executive_summary
├── final_investor_summary.sql            - Deliverable
├── summary_final.csv                     - CSV export of key market metrics and competitiveness scores for all California cities
└── summary_full.csv                      - CSV export of key market metrics and market classifications for 10 major California cities
README.md
```
