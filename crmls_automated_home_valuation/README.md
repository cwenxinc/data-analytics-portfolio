# Single-Family Home Valuation
This project develops automated valuation models (AVMs) to predict the sales prices of single-family homes in California, supporting IDX Exchange in estimating property values for its customers.

The project uses monthly sales records from the California Regional Multiple Listing Service (CRMLS) from January 2024 through June 2026, totaling 663,761 records. After filtering for single-family homes according to the project charter, 334,704 records remain for analysis and model development.

## Modeling
The project uses a chronological split to prevent future market conditions from leaking into training. June 2026 is used for testing, May 2026 for validation, and January 2025 through April 2026 (totaling 16 months) for training. The length of the training window is tuned during the iteration process.
### Validation Results
A sequence of machine learning models is developed, with each model tuned to optimize Median Absolute Percentage Error (MdAPE), while other performance metrics such as Mean Absolute Percentage Error (MAPE) and R<sup>2</sup> are included for reference. The table below summarizes the top-performing model from each category based on validation MdAPE: 
| Header 1 | Header 2 | Header 3 |
| --- | --- | --- |
| Row 1, Cell 1 | Row 1, Cell 2 | Row 1, Cell 3 |
| Row 2, Cell 1 | Row 2, Cell 2 | Row 2, Cell 3 |
The two gradient boosting models achieve sub 8% MdAPE on the validation set and are then further evaluated for predictive accuracy and stability. 
### Test Results
The two gradient boosting models achieve sub 8% MdAPE on the validation set and are then further evaluated for predictive accuracy and stability. 


## Directory Structure
