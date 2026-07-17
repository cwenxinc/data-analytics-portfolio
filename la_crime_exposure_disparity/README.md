# Racial Disparities in Crime Victimization in Los Angeles

This project analyzes 1,000,000+ crime records from the Los Angeles Police Department (2020–2024) to investigate patterns of crime exposure across major racial groups in Los Angeles. The analysis includes data cleaning, exploratory visualization, and statistical testing to assess whether observed differences are statistically significant.

The raw data and metadata documentation are available [here](https://data.lacity.org/Public-Safety/Crime-Data-from-2020-to-2024/2nrs-mtv8/about_data). Deliverables include **R scripts** documenting the data preparation and analysis pipeline, along with **an analytical paper** presenting the methodology and findings.

## Key Findings


## Directory Structure
```
paper.pdf                            - Final report that synthesizes methods and findings
scripts
├── la_crimes_analysis.Rmd           - Examines the association between crime exposure and race through visualization and permutation tests
├── la_crimes_preprocessing.Rmd      - Loads, cleans and aggregates crime records
└── simulation_studies.Rmd           - Assesses the robustess of permutation tests through Type I error, power, and exchangeability assumption
README.md
```
