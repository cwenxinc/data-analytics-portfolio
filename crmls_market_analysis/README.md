# CRMLS Market Analysis
This project analyzes 600,000+ California MLS real estate listings from January 2024 to April 2026 using ***Pandas*** and ***Tableau*** to uncover trends in pricing, supply, sales volume, and brokerage performance across cities and property types.

## Deliverables
**Market analysis** features three interactive dashboards covering sales trends, supply and demand comparison, and the relationship between sales and mortgage rates. The dashboards are linked [here](https://public.tableau.com/views/market_analysis_17794744134230/SalesTrends?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link), and PDF snapshots for a selected city and property type are included in this directory.

**Competitive analysis** features four interactive dashboards covering top-performing agents by sales, top-performing brokerages by sales, brokerage performance in sales speed and pricing, and sales distribution. The dashboards are linked [here](https://public.tableau.com/views/competitive_analysis_17794803740340/TopAgents?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link), and PDF snapshots for a selected city and/or property type are included in this directory.

## Key Findings


## Directory Structure
scripts
├── listed_aggregate.py         - Loads and combines monthly listings
├── listed_preprocess.py        - Profiles data quality and cleans listing records
├── sold_aggregate.py           - Loads and combines monthly sales
└── sold_preprocess.py          - Profiles data quality and cleans sales records
dashboards
├── competitive_landscape.pdf   - Snapshot of competitive analysis dashboards
└── sales_trends.pdf            - Snapshot of market analysis dashboards
README.md
