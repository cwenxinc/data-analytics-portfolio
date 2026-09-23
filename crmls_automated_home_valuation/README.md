# Single-Family Home Valuation
This project develops automated valuation models (AVMs) to predict the sales prices of single-family homes in California, supporting IDX Exchange in estimating property values for its customers.

The project uses monthly sales records from the California Regional Multiple Listing Service (CRMLS) from January 2024 through June 2026, totaling 663,761 records. After filtering for single-family homes according to the project charter, 334,704 records remain for analysis and model development.

## Iteration Timeline
The project uses a chronological data split to prevent future market conditions from leaking into model development. June 2026 is reserved for testing, May 2026 for validation, and January 2025 through April 2026 (16 months) for training. The training window length is tuned during model development.

The feature set is progressively reduced to 16 features across four categories:
- Property location: county, city, school district
- Construction history: property age
- Layout: living area, bedrooms, bathrooms, lot size
- Amenities: garage, pool, fireplace, view

A sequence of machine learning models is developed and tuned using validation MdAPE as the primary metric, with MAPE, R<sup>2</sup>, and other metrics reported for additional context. The two top-performing gradient boosting models, both achieving sub-8% validation MdAPE, are evaluated on the test set for predictive accuracy and then assessed through rolling-origin backtesting for predictive stability.

| Model | MdAPE | MAPE | MAE | RMSE | R<sup>2</sup> |
| --- | --- | --- | --- | --- | --- |
| XGBoost | 7.62% | 11.32% | $153304 | $300825 | 0.8965 | 
| LightGBM | 7.87% | 11.07% | $149700 | $290822 | 0.9033 |

## Directory Structure
