import numpy as np
import pandas as pd
# NOTE: geopy provides access to a free API that can be used to retrieve geographic coordinates from address data; see Part III for details
# from geopy.geocoders import Nominatim
# import time

listed = pd.read_csv('raw-data/listed_raw.csv')
listed.shape # (891983, 84)

"""
Part I: Filter for residential listings
"""

listed['PropertyType'].unique()
listed_residential = listed[listed['PropertyType'] == 'Residential']
listed_residential.shape # 566673 records retained


"""
Part II: Merge in mortgage rate data
"""

# derive year-month key from listing contract date
listed_residential['year_month'] = pd.to_datetime(listed_residential['ListingContractDate']).dt.to_period('M')

# pull mortgage rate data from FRED and create a matching year-month key
url = "https://fred.stlouisfed.org/graph/fredgraph.csv?id=MORTGAGE30US"
mortgage = pd.read_csv(url, parse_dates=['observation_date'])
mortgage.columns = ['date', 'rate_30yr_fixed']
mortgage['year_month'] = mortgage['date'].dt.to_period('M')
mortgage_monthly = mortgage.groupby('year_month')['rate_30yr_fixed'].mean().reset_index()

# merge monthly listings and mortgage rates
listed_residential_with_rates = listed_residential.merge(mortgage_monthly, on='year_month', how='left')
listed_residential_with_rates.columns
listed_residential_with_rates.shape
listed_residential_with_rates['rate_30yr_fixed'].isna().sum() # verify the merge was successful

listed_residential_with_rates.to_csv("raw-data/listed_residential_with_rates_raw.csv", index=False)


"""
Part III: Validate data
"""

listed_full = pd.read_csv("raw-data/listed_residential_with_rates_raw.csv")
listed_full = listed_full.replace(r'^\s*$', np.nan, regex=True) # convert blank strings to NaNs to ensure they are handled as missing values

# (i) flag fields with a significant amount of missing values
null_counts = listed_full.isna().sum()
null_percs = listed_full.isna().mean() * 100
null_table = pd.DataFrame({
    'null count': null_counts,
    'null percentage': null_percs
})
# look into fields with over 90% of values missing
mask_high_null_perc = null_percs > 90
null_table[mask_high_null_perc] # no field of interest in this list
fields_high_null_perc = listed_full.columns[mask_high_null_perc]
# look into fields of interest
# NOTE: unlike sales, we expect some listings to miss close price, purchase contract date, or close date
null_table.loc[['OriginalListPrice', 'ListPrice',                       # 14% (812 records) missing original list price
                'DaysOnMarket', 
                'LivingArea', 'BedroomsTotal', 'BathroomsTotalInteger', # 10% (580 records) missing living area, 3% (154 records) missing bedrooms, 1% (57 records) missing bathrooms
                'ListingContractDate']]                                 

# (ii) flag redundant fields
fields_redundant = [field for field in listed_full.columns if field.endswith('.1')]

# (iii) validate data types
# convert date fields to datetime
date_fields = ['ListingContractDate', 'PurchaseContractDate', 'CloseDate', 'ContractStatusChangeDate']
listed_full[date_fields] = listed_full[date_fields].apply(pd.to_datetime)
# convert numeric fields to numeric
numeric_fields = ['ClosePrice', 'OriginalListPrice', 'ListPrice', 'DaysOnMarket', 
                  'LivingArea', 'BedroomsTotal', 'BathroomsTotalInteger', 
                  'LotSizeAcres', 'LotSizeArea', 'LotSizeSquareFeet', 'GarageSpaces',
                  'YearBuilt', 
                  'Latitude', 'Longitude', 
                  'rate_30yr_fixed']
listed_full[numeric_fields] = listed_full[numeric_fields].apply(pd.to_numeric)

# (iv) flag records with invalid numeric values
# look into pricing, time to sell, and living space
listed_full['invalid_price_flag'] = (listed_full['OriginalListPrice'] <= 0) | (listed_full['ListPrice'] <= 0) | (listed_full['ClosePrice'] <= 0)
listed_full['negative_dom_flag'] = listed_full['DaysOnMarket'] < 0
listed_full['invalid_living_space_flag'] = (listed_full['LivingArea'] <= 0) | (listed_full['BedroomsTotal'] < 0) | (listed_full['BathroomsTotalInteger'] < 0)
# look into coordinates
# NOTE: the section below describes a geocoding procedure intended to recover missing coordinates from unparsed addresses; the procedure was not run because it would require significant computational resources
# geocoder = Nominatim(user_agent="crmls_listed")
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
# mask_missing_coord = listed_full["Latitude"].isna() | listed_full["Longitude"].isna()
# addresses = listed_full.loc[mask_missing_coord, "UnparsedAddress"].dropna().unique() # exclude duplicate addresses to facilitate geocoding
# coords_geocoded = pd.DataFrame(
#     [(address, *geocode(address)) for address in addresses],
#     columns=["UnparsedAddress", "lat_geocoded", "lon_geocoded"]
# )
#
# listed_full = listed_full.merge(coords_geocoded, on="UnparsedAddress", how="left")
# listed_full["Latitude"] = listed_full["Latitude"].fillna(listed_full["lat_geocoded"])
# listed_full["Longitude"] = listed_full["Longitude"].fillna(listed_full["lon_geocoded"])
# listed_full = listed_full.drop(columns=["lat_geocoded", "lon_geocoded"])
ca_lat = [32.5, 43]
ca_lon = [-124.26, -114.8]
mask_coord_out_of_range = (~listed_full['Longitude'].between(ca_lon[0], ca_lon[1])) | (~listed_full['Latitude'].between(ca_lat[0], ca_lat[1]))
mask_coord_not_missing = ~listed_full['Longitude'].isna() & ~listed_full['Latitude'].isna()
listed_full['outside_ca_flag'] = mask_coord_out_of_range & mask_coord_not_missing # only examine records without any missing coordinate

# (v) flag records with invalid dates
# NOTE: listing data represents the full market supply and includes properties that have not gone through the full sales cycle (i.e., those not yet closed)
listed_full['MlsStatus'].unique() # properties are either active, active under contract, pending, closed, or coming soon
# look into pending listings
mask_pending = listed_full['MlsStatus'] == "Pending"
listed_full['pending_listing_after_purchase_flag'] = listed_full[mask_pending]['ListingContractDate'] > listed_full[mask_pending]['PurchaseContractDate']
listed_full['pending_closed_while_pending_flag'] = ~listed_full[mask_pending]['CloseDate'].isna()
listed_full['pending_missing_purchase_date_flag'] = listed_full[mask_pending]['PurchaseContractDate'].isna()
# look into closed listings
mask_closed = listed_full['MlsStatus'] == "Closed"
listed_full['closed_purchase_after_close_flag'] = listed_full[mask_closed]['PurchaseContractDate'] > listed_full[mask_closed]['CloseDate']
listed_full['closed_listing_after_close_flag'] = listed_full[mask_closed]['ListingContractDate'] > listed_full[mask_closed]['CloseDate']
listed_full['closed_listing_after_purchase_flag'] = listed_full[mask_closed]['ListingContractDate'] > listed_full[mask_closed]['PurchaseContractDate']
listed_full['closed_missing_dates_flag'] = listed_full[mask_closed]['PurchaseContractDate'].isna() | listed_full[mask_closed]['CloseDate'].isna()
listed_full['closed_missing_close_price_flag'] = listed_full[mask_closed]['ClosePrice'].isna() # NOTE: this step further validates pricing, as closed listings are expected to have close prices
# look into active under contract listings
# NOTE: active under contract listings differ from pending listings in contingencies (in process vs all met)
mask_undercontract = listed_full['MlsStatus'] == "ActiveUnderContract"
listed_full['undercontract_listing_after_purchase_flag'] = listed_full[mask_undercontract]['ListingContractDate'] > listed_full[mask_undercontract]['PurchaseContractDate']
listed_full['undercontract_closed_while_under_contract_flag'] = ~listed_full[mask_undercontract]['CloseDate'].isna()
listed_full['undercontract_missing_purchase_date_flag'] = listed_full[mask_undercontract]['PurchaseContractDate'].isna()
# look into active listings
mask_active = listed_full['MlsStatus'] == "Active"
listed_full['active_purchased_while_active_flag'] = ~listed_full[mask_active]['PurchaseContractDate'].isna()
listed_full['active_closed_while_active_flag'] = ~listed_full[mask_active]['CloseDate'].isna()
# look into coming soon listings
mask_coming = listed_full['MlsStatus'] == "ComingSoon"
listed_full['coming_purchased_while_coming_flag'] = ~listed_full[mask_coming]['PurchaseContractDate'].isna() # none
listed_full['coming_closed_while_coming_flag'] = ~listed_full[mask_coming]['CloseDate'].isna()               # none


"""
Part IV: Clean data
"""

# (i) remove invalid records
mask_date_flag = listed_full.columns.str.startswith(("closed", "pending", "undercontract", "active", "coming"))
date_flags = listed_full.columns[mask_date_flag]
mask_dates_valid = ~listed_full[date_flags].fillna(False).any(axis=1) # NOTE: date validation rules differed by MLS status; during each status-specific check, records from other statuses were temporarily set to NaN and later filled with False before filtering
mask_others_valid = ~(listed_full['invalid_price_flag'] |
                      listed_full['invalid_living_space_flag'] | 
                      listed_full['negative_dom_flag'] | 
                      listed_full['outside_ca_flag'])
listed_valid = listed_full[mask_dates_valid & mask_others_valid]
listed_valid.shape # 536903 records retained

# (ii) remove records missing core values
listed_core_not_missing = listed_valid.dropna(subset=['OriginalListPrice', 'LivingArea'])
listed_core_not_missing.shape                           # 535739 records retained
listed_core_not_missing.shape[0] / listed_full.shape[0] # 94.5% of raw records retained

# (iii) remove redundant fields
# redundant fields
listed_clean = listed_core_not_missing.drop(columns=fields_redundant)
listed_clean.shape[1] # 11 fields removed
# fields with a significant amount of missing values
listed_clean = listed_clean.drop(columns=fields_high_null_perc)
listed_clean.shape[1] # 13 fields removed
# fields used to flag invalid records
mask_flag = listed_clean.columns.str.endswith("_flag")
flags = listed_clean.columns[mask_flag]
listed_clean = listed_clean.drop(columns=flags)
listed_clean.shape[1] # 19 fields removed
# field that has become non-informative after filtering
listed_clean = listed_clean.drop(columns='PropertyType')
listed_clean.shape[1] # 61 fields retained

listed_clean.shape # (535739, 61)
listed_clean.to_csv("clean-data/listed_residential_with_rates_clean.csv", index=False)


"""
Part V: Compute market metrics and handle outliers
"""

# compute metrics
listed_clean['price_ratio'] = listed_clean['ClosePrice'] / listed_clean['OriginalListPrice']
listed_clean['price_per_sq_ft'] = listed_clean['ClosePrice'] / listed_clean['LivingArea']
listed_clean['listing_to_contract_days'] = (listed_clean['PurchaseContractDate'] - listed_clean['ListingContractDate']).dt.days
listed_clean['contract_to_close_days'] = (listed_clean['CloseDate'] - listed_clean['PurchaseContractDate']).dt.days

metrics = ['OriginalListPrice', 'ClosePrice', 'price_ratio', 'price_per_sq_ft', 
           'DaysOnMarket', 'listing_to_contract_days', 'contract_to_close_days',  
           'LivingArea', 'BedroomsTotal', 'BathroomsTotalInteger']
listed_clean[metrics].describe(percentiles=[0.1, 0.25, 0.5, 0.75, 0.9])

# flag outliers
# NOTE: IQR is chosen over standard deviation because the data exhibits skewness and does not follow a normal distribution
# NOTE: lower bound is not applied to days on market, listing to contract days, contract to close days, bedrooms, and bathrooms because it can produce non-negative thresholds and incorrectly flag near-zero values as outliers
metrics_subset = ['OriginalListPrice', 'ClosePrice', 'price_ratio', 'price_per_sq_ft', 'LivingArea']
q1 = listed_clean[metrics].quantile(0.25)
q3 = listed_clean[metrics].quantile(0.75)
iqr = q3 - q1
lower = q1 - 1.5 * iqr
upper = q3 + 1.5 * iqr
listed_clean['outlier_flag'] = (listed_clean[metrics_subset] < lower[metrics_subset]).any(axis=1) | (listed_clean[metrics] > upper).any(axis=1)
listed_clean.to_csv("clean-data/listed_residential_metrics_outliers_flagged.csv", index=False)

# remove outliers
listed_outliers_removed = listed_clean[~listed_clean['outlier_flag']]
listed_outliers_removed.shape # 417975 records retained
listed_outliers_removed.shape[0] / listed_clean.shape[0] # 78% retained from clean data
listed_outliers_removed.shape[0] / listed_full.shape[0]  # 73.8% retained from raw data
listed_outliers_removed[metrics].describe(percentiles=[0.1, 0.25, 0.5, 0.75, 0.9])

listed_outliers_removed = listed_outliers_removed.drop(columns='outlier_flag')
listed_outliers_removed.to_csv("clean-data/listed_residential_metrics_outliers_removed.csv", index=False)