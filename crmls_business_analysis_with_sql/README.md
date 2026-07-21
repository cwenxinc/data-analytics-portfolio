# CRMLS Business Analysis
This project analyzes California MLS real estate data across three ***MySQL*** tables using ***DBeaver*** to answer key business questions about the California housing market.

## Directory Structure
Each SQL file applies specific SQL concepts to a practical business scenario. The final SQL script produces an executive summary of market conditions across California cities, including a composite competitiveness score and a market classification (competitive, balanced, or buyer opportunity) for each city. Each file begins with a summary of the business question and key findings.
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
├── summary_final.csv                     - CSV export of key market metrics and market classifications for 10 major California cities
└── summary_full.csv                      - CSV export of key market metrics and competitiveness scores for all California cities
README.md
```

## Key Findings
- Mission Hills, Placerville, and Rio Linda are California's fastest-moving markets, with every home selling within 7 days.
- Montrose, Pacheco, California Valley, and 120 other cities have less than one month of inventory relative to historical sales demand, while 158 cities experience stagnant or declining new listing growth.
- Weekends attract the most open house activity statewide. Los Angeles and San Diego host the highest weekend volumes (150+ open houses per day), while Santa Monica has one of the highest open house rates relative to active listings (over 30%).
- All major California cities are classified as balanced markets relative to the statewide average, though each reaches that balance through a different combination of market conditions. For example, Oakland offsets slower sales and a longer inventory runway with stronger sale-to-list performance, while Sacramento offsets weaker pricing power with tighter inventory.

## Database
This analysis integrates data from three tables in the *rets* database:
- rets_property: active listings
- rets_openhouse: open house schedules and details, linked to rets_property via *L_DisplayId*
- california_sold: historical sales

## Tools Used
- MySQL (via Docker)
- DBeaver (Community edition)
