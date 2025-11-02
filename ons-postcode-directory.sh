#!/bin/bash
# ------------------------------------------------------------------------------
# Script: ons-postcode-directory.sh
# Description:
#   Downloads the latest ONS postcode directory,
#   cleans up, converts selected fields to Parquet (EPSG:4326).
# ------------------------------------------------------------------------------

# Strict mode: exit on error, undefined variables, and pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Prepare working directory
# ------------------------------------------------------------------------------
DATA_DIR="data/ons-postcode-directory"  # Define main data directory path
mkdir -p "$DATA_DIR"  # Create directory if it doesn't exist (with parents)
cd "$DATA_DIR"  # Change to data directory

# ------------------------------------------------------------------------------
# 2. Download and extract the ONS postcode directory dataset
# ------------------------------------------------------------------------------
echo
echo "Downloading the latest ONS postcode directory dataset from ArcGIS Hub..."

csv_file="ons-postcode-directory.csv"  # Define main CSV data filename
# Download the CSV file from ArcGIS Hub using curl with follow redirects
curl -L https://open-geography-portalx-ons.hub.arcgis.com/api/download/v1/items/2182d12973974897ab386222f0e0de81/csv?layers=1 -o $csv_file
echo

# ------------------------------------------------------------------------------
# 3. Convert CSV to Parquet using DuckDB
# ------------------------------------------------------------------------------

parquet_file="${csv_file%.*}.parquet"  # Generate Parquet filename by replacing .csv extension
echo
echo "Converting CSV to Parquet using DuckDB..."

# Use DuckDB to read CSV, transform data, and write to Parquet format
duckdb -c "
COPY (
  SELECT
    trim(PCDS) as postcode,     -- Postcode string with spaces removed from ends
    DOINTR as intr_date,        -- Date of introduction
    DOTERM as term_date,        -- Date of termination
    USRTYPIND as user_type,     -- User type indicator
    CTRY25CD as country,        -- Country code
    RGN25CD as region,          -- Region code
    CTY25CD as county,          -- County code
    LAD25CD as local_authority, -- Local Authority District
    PFA23CD as police_force,    -- Police force area code
    MSOA21CD as msoa,           -- Middle Layer Super Output Area code
    LSOA21CD as lsoa,           -- Lower Layer Super Output Area code
    OA21CD as oa,               -- Output Area code
    RUC21IND as rural_urban,    -- Rural-Urban classification indicator
    NPARK16CD as national_park, -- National Park code
    CASE WHEN LAT > 90 THEN NULL ELSE LAT END AS lat,   -- Set latitude to NULL if latitude is invalid (lat > 90)
    CASE WHEN LAT > 90 THEN NULL ELSE LONG END AS lon   -- Set longitude to NULL if latitude is invalid (lat > 90)
  FROM read_csv_auto('$csv_file', sample_size=-1)       -- Read entire file for schema detection
) TO '$parquet_file';  -- Output to Parquet file
"

# Compress the original CSV file to save disk space
gzip $csv_file

# ------------------------------------------------------------------------------
# 4. Display results
# ------------------------------------------------------------------------------
echo
echo "Conversion complete. Generated files:"
ls -lh  # List files with human-readable sizes

# ------------------------------------------------------------
# 5. Return to project root
# ------------------------------------------------------------
cd - >/dev/null  # Return to previous directory, suppress output
echo
echo "Done."
