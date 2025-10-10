#!/bin/bash
# ------------------------------------------------------------------------------
# Script: download_os_codepoint_open.sh
# Description:
#   Downloads the latest Ordnance Survey Code-Point Open dataset (GeoPackage),
#   extracts it, cleans up, converts selected fields to Parquet (EPSG:4326),
#   and runs postcode imputation.
# ------------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined var, or failed pipe instead of continuing silently.

# ------------------------------------------------------------------------------
# 1. Prepare working directory
# ------------------------------------------------------------------------------
DATA_DIR="data/os-codepoint-open"
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

# ------------------------------------------------------------------------------
# 2. Download and extract the Code-Point Open dataset
# ------------------------------------------------------------------------------
echo
echo "Downloading OS Code-Point Open dataset from Ordnance Survey Data Hub..."
curl -L "https://api.os.uk/downloads/v1/products/CodePointOpen/downloads?area=GB&format=GeoPackage&redirect" -o codepoint.zip
echo
echo "Extracting ZIP archive..."
unzip -o codepoint.zip >/dev/null
rm codepoint.zip

# Move relevant files to the current directory
mv Data/* .
mv Doc/licence.txt Doc/metadata.txt Doc/Codelist.xlsx .
rm -rf Data/ Doc/

# ------------------------------------------------------------------------------
# 3. Convert GeoPackage to Parquet (reproject + clean geometry)
# ------------------------------------------------------------------------------
gpkg_file=$(ls *.gpkg | head -n 1)
parquet_file="${gpkg_file%.*}.parquet"
echo
echo "Cleansing data using ogr2ogr..."
ogr2ogr "$parquet_file" "$gpkg_file" \
  -sql "SELECT postcode, country_code, admin_district_code, admin_ward_code, geometry 
        FROM codepoint 
        WHERE NOT ST_Equals(geometry, ST_GeomFromText('POINT(0 0)'))" \
  -t_srs EPSG:4326 \
  -makevalid

# ------------------------------------------------------------------------------
# 4. Run admin boundary imputation script
# ------------------------------------------------------------------------------
echo
echo "Running admin boundary imputation..."
cd ../../
uv run python os-codepoint-impute.py

# ------------------------------------------------------------------------------
# 5. Display final results
# ------------------------------------------------------------------------------
echo
echo "Process complete. Generated files:"
ls -lh "$DATA_DIR"

# Return to project root
echo
echo "Done."

