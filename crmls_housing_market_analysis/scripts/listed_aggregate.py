import numpy as np
import pandas as pd

# aggregate all monthly listings in 2024
months_2024 = [f"{m:02d}" for m in range(1, 13)]
files_2024 = [f"raw-data/CRMLSListing2024{m}.csv" for m in months_2024]
listed_2024 = pd.concat(pd.read_csv(f) for f in files_2024)
listed_2024.shape # (383920, 84)

# aggregate all monthly listings in 2025
months_2025 = [f"{m:02d}" for m in range(1, 13)]
files_2025 = [f"raw-data/CRMLSListing2025{m}.csv" for m in months_2025]
listed_2025 = pd.concat(pd.read_csv(f) for f in files_2025)
listed_2025.shape # (363315, 82)

# aggregate all available monthly listings in 2026 (up to April)
months_2026 = [f"{m:02d}" for m in range(1, 5)]
files_2026 = [f"raw-data/CRMLSListing2026{m}.csv" for m in months_2026]
listed_2026 = pd.concat(pd.read_csv(f) for f in files_2026)
listed_2026.shape # (144748, 82)

# NOTE: 2024 data has 2 more fields than 2025 and 2026 data
# investigate field discrepancy
np.sum(listed_2025.columns != listed_2026.columns) # 2025 and 2026 fields match exactly
set(listed_2024) - set(listed_2025)                # 2025 and 2026 data don't have buyer agency compensation and buyer agency compensation type, which are not essential information
set(listed_2024) - set(listed_2026)

# aggregate all monthly listings from 2024-2026
listed = pd.concat([listed_2024, listed_2025, listed_2026])
listed.shape # (891983, 84)
listed.columns

listed.to_csv("raw-data/listed_raw.csv", index=False)