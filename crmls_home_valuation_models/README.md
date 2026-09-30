# CRMLS Single-Family Home Valuation
This project develops automated valuation models (AVMs) using ***Scikit-learn*** to estimate the sales prices of single-family homes in California. The final model is deployed with ***Streamlit*** for public use at IDX Exchange. Access the deployed app [here](https://ca-single-family-home-value-estimator.streamlit.app/).

The project uses monthly sales records from the California Regional Multiple Listing Service (CRMLS) from January 2024 through June 2026, totaling 663,761 records. After filtering for single-family homes according to the project charter, 334,704 records remain for model development.

## Preprocessing
Data preprocessing is performed in two stages:
- Data cleaning: Records are standardized, deduplicated, and filtered for logically invalid entries. Features that could introduce target leakage by approximating sales price, reflecting pricing strategy, or revealing post-close information are removed.
- Data transformation: Records are split chronologically into training, validation, and test sets. Imputation, scaling, encoding, and outlier removal are then applied, with transformation rules—such as outlier thresholds and imputation values—learned from the training set and applied unchanged to the validation and test sets.

For details, see `02_data_cleaning.ipynb` and `03_data_transformation.ipynb` under `scripts/`. Some transformations are implemented separately in `preprocess.py` under `utilities/` to help streamline the preprocessing pipeline.

## Model Development
June 2026 (the most recent month available) is reserved for testing, May 2026 for validation, and January 2025–April 2026 for training. The training window is extended from 12 to 16 months based on validation performance.

The feature set is reduced to 15 features across four categories:
- Property location: county, city, zipcode, school district
- Construction history: property age
- Layout: living area, bedrooms, bathrooms, stories, lot size
- Amenities: parking space, garage, pool, fireplace, view

A sequence of machine learning models is trained and tuned using validation MdAPE as the primary metric, with MAPE, R<sup>2</sup>, and other metrics reported for reference. The two top-performing models, both achieving sub-8% validation MdAPE, are then evaluated on the test set for predictive accuracy and assessed through rolling-origin backtesting for stability. For details, see `04_modeling.ipynb` under `scripts/`.

## Model Performance
Both models show consistent predictive accuracy on the test set, with performance declining for higher-priced homes.

<div align="center">

| Model | MdAPE | MAPE | MAE | RMSE | R<sup>2</sup> |
| --- | --- | --- | --- | --- | --- |
| XGBoost | 7.66% | 11.43% | $155,919 | $307,390 | 0.8919 | 
| LightGBM | 7.88% | 11.20% | $151,386 | $293,459 | 0.9015 |

<sub>Table 1: Test-set performance of the two top-performing models from validation.</sub>

</div>

<div align="center">

| Model | Q1 | Q2 | Q3 | Q4 |
| --- | --- | --- | --- | --- |
| XGBoost | 6.58% | 5.88% | 8.32% | 11.30% |
| LightGBM | 6.93% | 6.23% | 8.40% | 11.06% |

<sub>Table 2: Test-set MdAPE of the two top-performing models by sales price quartile.</sub>

</div>

Rolling-origin backtests also show stable performance. XGBoost achieves a mean MdAPE of 7.67% (SD: 0.16%), while LightGBM achieves 7.83% (SD: 0.11%). LightGBM is ultimately selected for deployment over XGBoost due to its superior computational efficiency and predictive stability.

## Directory Structure
```
app/
├── assets/
│   └── logo.png                   - Company logo
├── app.py                         - Defines the app interface
├── model.pkl                      - Stores the serialized LightGBM model
└── requirements.txt               - Lists the libraries and versions required for deployment
scripts/
├── 01_exploration.ipynb           - Explores target and feature distributions
├── 02_data_cleaning.ipynb         - Validates merged sales records
├── 03_data_transformation.ipynb   - Splits merged data chronologically and applies training-based preprocessing
└── 04_modeling.ipynb              - Trains and evaluates machine learning models
utilities/
├── merge.py                       - Merges monthly sales records from January 2024–June 2026
└── preprocess.py                  - Creates helper functions to streamline and scale training-based preprocessing
presentation.pdf                   - Summarizes model development and performance
README.md
```
