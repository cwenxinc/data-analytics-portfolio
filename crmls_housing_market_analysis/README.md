# CRMLS Market Analysis
This project analyzes 600,000+ California MLS real estate listings from January 2024 to April 2026 using ***Pandas*** and ***Tableau*** to uncover trends in pricing, supply, sales volume, and brokerage performance across cities and property types.

## Deliverables
**Market analysis** features three interactive dashboards covering sales trends, supply and demand comparison, and mortgage rates and sales comparison. The dashboards are linked [here](https://public.tableau.com/views/market_analysis_17794744134230/SalesTrends?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link), and PDF snapshots for a selected city and property type are included in this directory.

**Competitive analysis** features four interactive dashboards covering top-performing agents by sales, top-performing brokerages by sales, brokerage performance in sales speed and sale-to-list pricing, and sales distribution. The dashboards are linked [here](https://public.tableau.com/views/competitive_analysis_17794803740340/TopAgents?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link), and PDF snapshots for a selected city and/or property type are included in this directory.

## Key Findings
The following findings focus on the single-family housing market in Fontana, California:
- The market remained healthy throughout the study period, with homes typically selling within 30 days and at or near asking price, though sales activity slowed modestly during the winter months.
- Market conditions shifted over time, favoring buyers from mid-2024 through mid-2025 before shifting toward sellers in late 2025. Early 2026 showed signs of returning to a more buyer-friendly market.
- Sales volume generally increased with transaction count, but higher-value properties enabled some agents to outperform peers despite closing fewer sales. Derek Oie, Melissa Handler, and Todd Myatt led in both transaction count and sales volume, while Rebecca Flores generated higher sales volume than some agents with more transactions.
- RE/MAX TIME REALTY dominated market share, while smaller brokerages remained competitive in sales efficiency and pricing power.

Other findings:
- Single-family home sales were concentrated in inland California, while coastal markets achieved the highest sale prices.
- Mortgage rates and sales activity showed an inverse relationship: rising rates in late 2024 coincided with weaker sales, while falling rates in 2025 coincided with a sustained increase in sales. Although mortgage rates may influence affordability and buyer behavior, additional factors should be considered when interpreting these trends.

## Directory Structure
```
scripts
├── listed_aggregate.py         - Loads and combines monthly listings
├── listed_preprocess.py        - Profiles data quality and cleans listing records
├── sold_aggregate.py           - Loads and combines monthly sales
└── sold_preprocess.py          - Profiles data quality and cleans sales records
dashboards
├── competitive_landscape.pdf   - Snapshot of competitive analysis dashboards
└── sales_trends.pdf            - Snapshot of market analysis dashboards
README.md
```
