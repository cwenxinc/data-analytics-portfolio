import numpy as np
import pandas as pd
# NOTE: geopy provides access to a free API that can be used to retrieve geographic coordinates from address data; see Part III for details
# from geopy.geocoders import Nominatim
# import time

sold = pd.read_csv('raw-data/sold_raw.csv')
sold.shape # (615994, 84)

"""
Part I: Filter for residential sales
"""

sold['PropertyType'].unique()
mask_residential = sold['PropertyType'] == 'Residential'
sold_residential = sold[mask_residential]
sold_residential.shape # 414184 records retained


"""
Part II: Merge in mortgage rate data
"""

# derive year-month key from close date
sold_residential['year_month'] = pd.to_datetime(sold_residential['CloseDate']).dt.to_period('M')

# pull mortgage rate data from FRED and create a matching year-month key
url = "https://fred.stlouisfed.org/graph/fredgraph.csv?id=MORTGAGE30US"
mortgage = pd.read_csv(url, parse_dates=['observation_date'])
mortgage.columns = ['date', 'rate_30yr_fixed']
mortgage['year_month'] = mortgage['date'].dt.to_period('M')
mortgage_monthly = mortgage.groupby('year_month')['rate_30yr_fixed'].mean().reset_index()

# merge monthly sales and mortgage rates
sold_residential_with_rates = sold_residential.merge(mortgage_monthly, on='year_month', how='left')
sold_residential_with_rates.shape
sold_residential_with_rates.columns
sold_residential_with_rates['rate_30yr_fixed'].isna().sum() # verify the merge was successful

sold_residential_with_rates.to_csv("raw-data/sold_residential_with_rates_raw.csv", index=False)


"""
Part III: Validate data
"""

sold_full = pd.read_csv('raw-data/sold_residential_with_rates_raw.csv') # NOTE: mixed types warning
sold_full['MlsStatus'].unique() # confirm that all sales are indeed closed
sold_full = sold_full.replace(r'^\s*$', np.nan, regex=True) # convert blank strings to NaNs to ensure they are handled as missing values

# (i) flag fields with a significant amount of missing values
null_counts = sold_full.isna().sum()
null_percs =  sold_full.isna().mean() * 100
null_table = pd.DataFrame({
    'null count': null_counts,
    'null percentage': null_percs
})
# look into fields with over 90% of values missing
mask_high_null_perc = null_percs > 90
null_table[mask_high_null_perc] # no field of interest in this list
fields_high_null_perc = sold_full.columns[mask_high_null_perc]
# look into fields of interest
null_table.loc[['OriginalListPrice', 'ListPrice', 'ClosePrice',              # 18% (759 records) missing original list price, 2 records missing close price
                'DaysOnMarket', 
                'LivingArea', 'BedroomsTotal', 'BathroomsTotalInteger',      # 5.6% (234 records) missing living area, 11 records missing bedrooms, 1.7% (69 records) missing bathrooms
                'CloseDate', 'PurchaseContractDate', 'ListingContractDate']] # 4.7% (195 records) missing purchase date, 1 record missing listing date

# (ii) validate data types
# convert date fields to datetime
date_fields = ['ListingContractDate', 'PurchaseContractDate', 'CloseDate', 'ContractStatusChangeDate']
sold_full[date_fields] = sold_full[date_fields].apply(pd.to_datetime)
# convert numeric fields to numeric
numeric_fields = ['ClosePrice', 'OriginalListPrice', 'ListPrice', 'DaysOnMarket', 
                  'LivingArea', 'BedroomsTotal', 'BathroomsTotalInteger', 
                  'LotSizeAcres', 'LotSizeArea', 'LotSizeSquareFeet', 'GarageSpaces',
                  'YearBuilt', 
                  'Latitude', 'Longitude', 
                  'rate_30yr_fixed']
sold_full[numeric_fields] = sold_full[numeric_fields].apply(pd.to_numeric)

# (iii) flag records with invalid date order
sold_full['listing_after_purchase_flag'] = sold_full['ListingContractDate'] > sold_full['PurchaseContractDate']
sold_full['listing_after_close_flag'] = sold_full['ListingContractDate'] > sold_full['CloseDate']
sold_full['purchase_after_close_flag'] = sold_full['PurchaseContractDate'] > sold_full['CloseDate']

# (iv) flag records with invalid numeric values
# look into pricing, time to sell, and living space
sold_full['invalid_price_flag'] = (sold_full['OriginalListPrice'] <= 0) | (sold_full['ListPrice'] <= 0) | (sold_full['ClosePrice'] <= 0)
sold_full['negative_dom_flag'] = sold_full['DaysOnMarket'] < 0
sold_full['invalid_living_space_flag'] = (sold_full['LivingArea'] <= 0) | (sold_full['BedroomsTotal'] < 0) | (sold_full['BathroomsTotalInteger'] < 0)
# look into coordinates
# NOTE: the section below describes a geocoding procedure intended to recover missing coordinates from unparsed addresses; the procedure was not run because it would require significant computational resources
# geocoder = Nominatim(user_agent="crmls_sold")
#
# def geocode(address):
#     if pd.isna(address): 
#         return (None, None)
#     try:
#         time.sleep(1) # apply rate limiting to prevent sending requests to the geocoding API too often
#         location = geocoder.geocode(address)
#         if location:
#             return location.latitude, location.longitude
#         return (None, None)
#     except Exception:
#         return (None, None)
#
# mask_missing_coord = sold_full["Latitude"].isna() | sold_full["Longitude"].isna()
# addresses = sold_full.loc[mask_missing_coord, "UnparsedAddress"].dropna().unique() # exclude duplicate addresses to facilitate geocoding
# coords_geocoded = pd.DataFrame(
#     [(address, *geocode(address)) for address in addresses],
#     columns=["UnparsedAddress", "lat_geocoded", "lon_geocoded"]
# )
#
# sold_full = sold_full.merge(coords_geocoded, on="UnparsedAddress", how="left")
# sold_full["Latitude"] = sold_full["Latitude"].fillna(sold_full["lat_geocoded"])
# sold_full["Longitude"] = sold_full["Longitude"].fillna(sold_full["lon_geocoded"])
# sold_full = sold_full.drop(columns=["lat_geocoded", "lon_geocoded"])
ca_lat = [32.5, 43]
ca_lon = [-124.26, -114.8]
mask_coord_out_of_range = (~sold_full['Longitude'].between(ca_lon[0], ca_lon[1])) | (~sold_full['Latitude'].between(ca_lat[0], ca_lat[1]))
mask_coord_not_missing = ~sold_full['Longitude'].isna() & ~sold_full['Latitude'].isna()
sold_full['outside_ca_flag'] = mask_coord_out_of_range & mask_coord_not_missing # only examine records without any missing coordinate


"""
Part IV: Clean data
"""

# (i) remove invalid records
mask_flag = sold_full.columns.str.endswith("_flag")
flag_fields = sold_full.columns[mask_flag]
sold_valid = sold_full[~sold_full[flag_fields].any(axis=1)]
sold_valid.shape # 413003 records retained

# (ii) remove records missing core values
sold_core_not_missing = sold_valid.dropna(subset=['ListingContractDate', 'PurchaseContractDate', 'OriginalListPrice', 'ClosePrice', 'LivingArea'])
sold_core_not_missing.shape # 412011 records retained
sold_core_not_missing.shape[0] / sold_full.shape[0] # less than 1% removed

# (iii) remove redundant fields
# fields with a significant amount of missing values
sold_clean = sold_core_not_missing.drop(columns=fields_high_null_perc)
sold_clean.shape[1] # 15 fields removed
# fields used to flag invalid records
sold_clean = sold_clean.drop(columns=flag_fields)
sold_clean.shape[1] # 7 fields removed
# field that has become non-informative after filtering
sold_clean = sold_clean.drop(columns='PropertyType')
sold_clean.shape[1] # 70 fields retained

sold_clean.to_csv("clean-data/sold_residential_with_rates_clean.csv", index=False)


"""
Part V: Compute market metrics and handle outliers
"""

# compute metrics
sold_clean['price_ratio'] = sold_clean['ClosePrice'] / sold_clean['OriginalListPrice']
sold_clean['price_per_sq_ft'] = sold_clean['ClosePrice'] / sold_clean['LivingArea']
sold_clean['listing_to_contract_days'] = (sold_clean['PurchaseContractDate'] - sold_clean['ListingContractDate']).dt.days
sold_clean['contract_to_close_days'] = (sold_clean['CloseDate'] - sold_clean['PurchaseContractDate']).dt.days

metrics = ['OriginalListPrice', 'ClosePrice', 'price_ratio', 'price_per_sq_ft', 
           'DaysOnMarket', 'listing_to_contract_days', 'contract_to_close_days',  
           'LivingArea', 'BedroomsTotal', 'BathroomsTotalInteger']
sold_clean[metrics].describe(percentiles=[0.1, 0.25, 0.5, 0.75, 0.9])

# flag outliers
# NOTE: IQR is chosen over standard deviation because the data exhibits skewness and does not follow a normal distribution
# NOTE: lower bound is not applied to days on market, listing to contract days, contract to close days, bedrooms, and bathrooms because it can produce non-negative thresholds and incorrectly flag near-zero values as outliers
metrics_subset = ['OriginalListPrice', 'ClosePrice', 'price_ratio', 'price_per_sq_ft', 'LivingArea']
q1 = sold_clean[metrics].quantile(0.25)
q3 = sold_clean[metrics].quantile(0.75)
iqr = q3 - q1
lower = q1 - 1.5 * iqr
upper = q3 + 1.5 * iqr
sold_clean['outlier_flag'] = (sold_clean[metrics_subset] < lower[metrics_subset]).any(axis=1) | (sold_clean[metrics] > upper).any(axis=1)
sold_clean.to_csv("clean-data/sold_residential_metrics_outliers_flagged.csv", index=False)

# remove outliers
sold_outliers_removed = sold_clean[~sold_clean['outlier_flag']]
sold_outliers_removed.shape # 288604 records retained
sold_outliers_removed.shape[0] / sold_clean.shape[0] # 70% retained from clean data
sold_outliers_removed.shape[0] / sold_full.shape[0]  # 69.7% retained from raw data
sold_outliers_removed[metrics].describe(percentiles=[0.1, 0.25, 0.5, 0.75, 0.9])

sold_outliers_removed = sold_outliers_removed.drop(columns='outlier_flag')
sold_outliers_removed.to_csv("clean-data/sold_residential_metrics_outliers_removed.csv", index=False)