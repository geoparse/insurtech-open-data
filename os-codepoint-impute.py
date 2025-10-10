import warnings

import pandas as pd
import geopandas as gpd

warnings.filterwarnings("ignore")

"""
Clean and impute missing administrative codes for OS Code-Point Open postcode data.

This script performs the following steps:
1. Loads postcode point data from a Parquet file.
2. Normalises `country_code` values by replacing short codes (E/W/S) with full names
   ("England", "Wales", "Scotland").
3. Reads Ordnance Survey codelists (Excel sheets) for counties, districts, wards, and unitary
   authorities, building a lookup dictionary that maps area names to their official codes.
4. Replaces `admin_district_code`, `admin_ward_code`, and `country_code` values in the dataset
   using the lookup dictionary.
5. Identifies postcode points with missing administrative district codes and imputes them by
   performing a nearest-neighbour spatial join with points that have known codes.
6. Updates the missing `admin_district_code` and `admin_ward_code` fields with the recovered values.
7. Saves the cleaned and imputed dataset to a new Parquet file.

Output:
    A Parquet file containing postcode points with complete administrative district,
    ward, and country codes, suitable for spatial analysis and linkage with other datasets.
"""

print("  Reading the postcode file...")
gdf = gpd.read_parquet("./data/os-codepoint-open/codepo_gb.parquet")

gdf.loc[gdf.country_code.str.startswith("S", na=False), "country_code"] = "Scotland"
gdf.loc[gdf.country_code.str.startswith("E", na=False), "country_code"] = "England"
gdf.loc[gdf.country_code.str.startswith("W", na=False), "country_code"] = "Wales"

area_dict = {}
for sheet_name in [
    "CTY",
    "DIS",
    "DIW",
    "LBO",
    "LBW",
    "MTD",
    "MTW",
    "UTA",
    "UTE",
    "UTW",
]:
    df = pd.read_excel(
        "./data/os-codepoint-open/Codelist.xlsx", sheet_name=sheet_name, header=None
    )
    for _, row in df.iterrows():
        area_dict[row[1]] = row[0]

gdf["admin_district_code"] = gdf.admin_district_code.apply(
    lambda x: area_dict[x] if x in area_dict else x
)
gdf["admin_ward_code"] = gdf.admin_ward_code.apply(
    lambda x: area_dict[x] if x in area_dict else x
)
gdf["country_code"] = gdf.country_code.apply(
    lambda x: area_dict[x] if x in area_dict else x
)

print("  Imputing missing administrative data...")
# Split into known and missing district codes
kdf = gdf[gdf["admin_district_code"].notna()]  # known df
mdf = gdf[gdf["admin_district_code"].isna()]  # missing df

ndf = gpd.sjoin_nearest(  # nearest df
    mdf[["postcode", "geometry"]],
    kdf[["admin_district_code", "admin_ward_code", "geometry"]],
    how="left",
    #    max_distance=None,   # optional: limit to a search radius
    #   distance_col="dist"
)

ndf = ndf.drop(columns="index_right").drop_duplicates()

gdf.loc[gdf.admin_district_code.isnull(), "admin_district_code"] = ndf[
    "admin_district_code"
]
gdf.loc[gdf.admin_ward_code.isnull(), "admin_ward_code"] = ndf["admin_ward_code"]

print("  Exporting results to ./data/os-codepoint-open/codepo_gb.parquet...")
gdf.to_parquet("./data/os-codepoint-open/codepo_gb.parquet", index=False)
