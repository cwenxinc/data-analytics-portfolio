# CRMLS Single-Family Home Valuation
This project develops automated valuation models (AVMs) using ***Scikit-learn*** to predict California single-family home sales prices and deploys the final model with ***Streamlit*** for property valuation. Access the deployed app here[hyperlink to be included].

The project uses monthly sales records from the California Regional Multiple Listing Service (CRMLS) from January 2024 through June 2026, totaling 663,761 records. After filtering for single-family homes according to the project charter, 334,704 records remain for analysis and model development.

## Preprocessing
Data preprocessing is performed in two stages:
- Data cleaning: Records are standardized, deduplicated, and filtered for logically invalid records. Features that could introduce target leakage by approximating sales price or reflecting pricing strategy are also removed.
- Data transformation: Records are first split chronologically into training, validation, and test sets. Targeted transformations—including imputation, scaling, encoding, and outlier removal—are then applied. Transformation rules, such as outlier thresholds and imputation values, are learned from the training set and applied unchanged to the validation and test sets.

For details, see `02_data_cleaning.ipynb` and `03_data_transformation.ipynb` under `scripts/`. Some transformations are implemented separately in `preprocess.py` under `utilities/` to help streamline the preprocessing pipeline.

## Model Development
A chronological split is used instead of a random split to prevent future information from leaking into model development. June 2026 is reserved for testing, May 2026 for validation, and January 2025 through April 2026 for training. The training window is tuned and extended to 16 months based on validation performance.

The feature set is reduced to 16 features across four categories:
- Property location: county, city, school district, MLS area major, postal code
- Construction history: property age
- Layout: living area, bedrooms, bathrooms, stories, lot size
- Amenities: parking space, garage, pool, fireplace, view

A sequence of machine learning models is developed and tuned using validation MdAPE as the primary metric, with MAPE, R<sup>2</sup>, and other metrics reported for additional context. The two top-performing models, both achieving sub-8% validation MdAPE, are evaluated on the test set for predictive accuracy and then assessed through rolling-origin backtesting for predictive stability. For details, see `04_modeling.ipynb` under `scripts/`.

## Model Performance
Both models show consistent predictive accuracy on the test set, with performance declining for higher-priced homes.

<div align="center">

| Model | MdAPE | MAPE | MAE | RMSE | R<sup>2</sup> |
| --- | --- | --- | --- | --- | --- |
| XGBoost | 7.62% | 11.32% | $153,304 | $300,825 | 0.8965 | 
| LightGBM | 7.87% | 11.07% | $149,700 | $290,822 | 0.9033 |

<sub>Table 1: Test-set performance of the two top-performing models from validation.</sub>

</div>

<div align="center">

| Model | Q1 | Q2 | Q3 | Q4 |
| --- | --- | --- | --- | --- |
| XGBoost | 6.59% | 5.87% | 8.14% | 10.97% |
| LightGBM | 6.75% | 6.27% | 8.31% | 10.67% |

<sub>Table 2: Test-set MdAPE of the two top-performing models by sales price quartile.</sub>

</div>

Rolling-origin backtests also show stable performance. XGBoost achieves a mean MdAPE of 7.67% (SD: 0.15%), while LightGBM achieves 7.78% (SD: 0.10%).

## Directory Structure
```
scripts
├── 01_exploration.ipynb           - Explores target and feature distributions
├── 02_data_cleaning.ipynb         - Validates merged sales records
├── 03_data_transformation.ipynb   - Splits merged data chronologically and applies training-based preprocessing
└── 04_modeling.ipynb              - Trains and evaluates machine learning models
utilities
├── merge.py                       - Merges monthly sales records from Jan 2024 to June 2026
└── preprocess.py                  - Creates helper functions to help streamline and scale training-based preprocessing
presentation.pdf                   - Summarizes model development timeline and performance
README.md
```
