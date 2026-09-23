# Single-Family Home Valuation
This project develops automated valuation models (AVMs) using ***Scikit-learn*** to predict California single-family home sales prices and deploys the final model with ***Streamlit*** for property valuation.

The project uses monthly sales records from the California Regional Multiple Listing Service (CRMLS) from January 2024 through June 2026, totaling 663,761 records. After filtering for single-family homes according to the project charter, 334,704 records remain for analysis and model development.

## Preprocessing
Data preprocessing is performed in two stages:
1. Data cleaning: Records are standardized, deduplicated, and filtered for logically invalid records. Features that could introduce target leakage by approximating sales price or reflecting pricing strategy are also removed.
2. Data transformation: Records are first split chronologically into training, validation, and test sets. Targeted transformations—including imputation, scaling, encoding, and outlier removal—are then applied. Transformation rules, such as outlier thresholds and imputation values, are learned from the training set and applied unchanged to the validation and test sets to prevent future information from leaking into model development.

For details, see 02_data_cleaning.ipynb and 03_data_transformation.ipynb under scripts/. The transformation notebook imports helper functions from preprocess.py under utilities/ to streamline training-learned transformations.

## Iteration Timeline
The project uses a chronological data split to prevent future market conditions from leaking into model development. June 2026 is reserved for testing, May 2026 for validation, and January 2025 through April 2026 (16 months) for training. The training window length is tuned during model development.

The feature set is progressively reduced to 16 features across four categories:
- Property location: county, city, school district
- Construction history: property age
- Layout: living area, bedrooms, bathrooms, lot size
- Amenities: garage, pool, fireplace, view

A sequence of machine learning models is developed and tuned using validation MdAPE as the primary metric, with MAPE, R<sup>2</sup>, and other metrics reported for additional context. The two top-performing models, both achieving sub-8% validation MdAPE, are evaluated on the test set for predictive accuracy and then assessed through rolling-origin backtesting for predictive stability. 

## Model Performance
The table below summarizes the performance of the two top-performing models from validation on the test set. Both models achieve consistent predictive performance on the test set, though accuracy declines for home sold at higher price quartiles. Both models also achieve stable performance across rolling backtests, with XGBoost achieving a mean MdAPE of 7.67% with 0.15% standard deviation and LightGBM achieving a mean MdAPE of 7.77% with 0.10% standard deviation.

| Model | MdAPE | MAPE | MAE | RMSE | R<sup>2</sup> |
| --- | --- | --- | --- | --- | --- |
| XGBoost | 7.62% | 11.32% | $153,304 | $300,825 | 0.8965 | 
| LightGBM | 7.87% | 11.07% | $149,700 | $290,822 | 0.9033 |

## Directory Structure
