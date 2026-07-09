import numpy as np
import pandas as pd

# aggregate all monthly sales in 2024
months_2024 = [f"{m:02d}" for m in range(1, 13)]
files_2024 = [f"raw-data/CRMLSSold2024{m}.csv" for m in months_2024]
sold_2024 = pd.concat(pd.read_csv(f) for f in files_2024)
sold_2024.shape # (272491, 84)

# aggregate all monthly sales in 2025
months_2025 = [f"{m:02d}" for m in range(1, 13)]
files_2025 = [f"raw-data/CRMLSSold2025{m}.csv" for m in months_2025]
sold_2025 = pd.concat(pd.read_csv(f) for f in files_2025)
sold_2025.shape # (260104, 80)

# aggregate all available monthly sales in 2026 (up to April)
months_2026 = [f"{m:02d}" for m in range(1, 5)]
files_2026 = [f"raw-data/CRMLSSold2026{m}.csv" for m in months_2026]
sold_2026 = pd.concat(pd.read_csv(f) for f in files_2026)
sold_2026.shape # (83399, 80)

# NOTE: 2024 data has 4 more fields than 2025 and 2026 data
# investigate field discrepancy
np.sum(sold_2025.columns != sold_2026.columns)  # 2025 and 2026 data differ in 2 fields, latfilled and lonfilled
sold_2025.columns[sold_2025.columns != sold_2026.columns]
set(sold_2024.columns) - set(sold_2025.columns) # 2025 data don't have buyer agency compensation, buyer agency compensation type, originating system name, and originating system subname, none of which is essential information
set(sold_2024.columns) - set(sold_2026.columns) # 2026 data don't have buyer agency compensation, buyer agency compensation type, latfilled, and lonfilled, none of which is essential information

# aggregate all monthly sales from 2024-2026
sold = pd.concat([sold_2024, sold_2025, sold_2026])
sold.shape # (615994, 84)
sold.columns

sold.to_csv("raw-data/sold_raw.csv", index=False)