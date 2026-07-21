# Racial Disparities in Crime Victimization in Los Angeles

This project analyzes 1,000,000+ crime records from the Los Angeles Police Department (2020–2024) to investigate victimization patterns across major racial groups in Los Angeles. The analysis includes data cleaning, exploratory visualization, and hypothesis testing to assess whether observed group differences are statistically significant.

The raw data and metadata documentation are available [here](https://data.lacity.org/Public-Safety/Crime-Data-from-2020-to-2024/2nrs-mtv8/about_data). Deliverables include ***R scripts*** documenting the data preparation and analysis pipeline, along with ***an academic paper*** presenting the methodology and findings.

## Key Findings
Findings from exploratory analysis:
- Hispanic victims represented the largest share of victims throughout the day, followed by White, Black, and Asian victims. However, the hourly composition of victimization varied across racial groups; for example, the share of Hispanic victims declined around noon, whereas the share of White victims peaked during the same period.
- Property crimes accounted for a similar share of victimization across racial groups. In contrast, Asian victims had a relatively larger share of violent crimes, whereas Hispanic victims had a relatively larger share of sexual commodification offenses.

Findings from pairwise permutation tests:
*Note: The testing framework is described in detail in the Methods section of the paper*
- Across all racial group comparisons, observed total variation distances fell in the extreme tails of their corresponding null distributions, with all Bonferroni-adjusted p-values virtually equal to 0. These results provide strong evidence that crime type distributions differed across racial groups.
  - However, the magnitude of these differences varied across pairwise comparisons, with some pairs of racial groups exhibiting greater divergence in crime type distributions than others.
- Simulation studies revealed inflated type I error rates across all pairwise tests and high statistical power only for comparisons involving Black victims. Therefore, while the observed differences were statistically significant, their significance should be interpreted with caution.

## Directory Structure
```
racial_disparities_in_victimization.pdf     - Paper that synthesizes methods and findings
scripts
├── la_crimes_analysis.Rmd                  - Visually explores and then evaluates differences in victimization patterns using permutation tests
├── la_crimes_preprocessing.Rmd             - Loads, cleans and aggregates crime records
└── simulation_studies.Rmd                  - Assesses the robustess of permutation tests
README.md
```
