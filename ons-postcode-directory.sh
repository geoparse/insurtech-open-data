#!/bin/bash
# ------------------------------------------------------------------------------
# Script: ons-postcode-directory.sh
# Description:
#   Downloads the latest ONS postcode directory,
#   cleans up, converts selected fields to Parquet (EPSG:4326).
# ------------------------------------------------------------------------------

export LC_ALL=C

# Strict mode: exit on error, undefined variables, and pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Prepare working directory
# ------------------------------------------------------------------------------
DATA_DIR="data/ons-postcode-directory"
mkdir -p "$DATA_DIR"  # Create directory if it doesn't exist
cd "$DATA_DIR"  # Change to data directory

DOC_DIR="Documents"
AREA_DICT="ons-area-codes.csv"
TEMP_FILE=$(mktemp)

echo
echo "Downloading and Extracting the latest ONS postcode directory dataset from ArcGIS Hub..."
# Download the dataset from ArcGIS Hub
curl -L https://www.arcgis.com/sharing/rest/content/items/295e076b89b542e497e05632706ab429/data -o ons-postcode-directory.zip
# Extract the zip file ($_ represents the last argument from previous command)
unzip $_ "Documents/*" "User Guide/*"
# Remove the zip file after extraction to save space

rm *.zip

echo
echo "Extracting ONS area codes and names..."
# Find and process files matching the patterns
for pattern in "CTRY*.csv" "RGN*.csv" "CTY*.csv" "LAD*.csv" "PFA*.csv" "MSOA*2021*.csv" "LSOA*2021*.csv" "NPARK*.csv"; do
    # Find files matching the pattern
    for file in $DOC_DIR/$pattern; do
        echo "  $file"
        cut -d, -f1,2 "$file" | tr -d '\r' | tail -n +2 | grep -v '^,' >> "$TEMP_FILE"
    done
done

# Sort and deduplicate (like merging dicts)
sort -t, -u -k1,1 "$TEMP_FILE" > "$AREA_DICT"

echo "Combined area dictionary created."
echo "  $AREA_DICT"

# Clean up temp file
rm $TEMP_FILE

# ------------------------------------------------------------------------------
# 2. Download and extract the Code-Point Open dataset
# ------------------------------------------------------------------------------
echo
echo "Downloading the latest ONS postcode directory dataset from ArcGIS Hub..."

csv_file="ons-postcode-directory.csv"
# Download the CSV file from ArcGIS Hub using curl
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
# Return to project root
# ------------------------------------------------------------
cd - >/dev/null  # Return to previous directory, suppress output
echo
echo "Done."
