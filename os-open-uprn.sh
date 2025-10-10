#!/bin/bash
# ------------------------------------------------------------------------------
# Script: download_os_open_uprn.sh
# Description:
#   Downloads the latest Ordnance Survey Open UPRN dataset (CSV format),
#   extracts it, converts it to Parquet using DuckDB, and stores it locally.
# ------------------------------------------------------------------------------
set -euo pipefail  # Exit on error, undefined var, or failed pipe instead of continuing silently.

# ------------------------------------------------------------------------------
# 1. Prepare working directory
# ------------------------------------------------------------------------------
DATA_DIR="data/os-open-uprn"
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

# ------------------------------------------------------------------------------
# 2. Download and extract the OS Open UPRN dataset (CSV format)
# ------------------------------------------------------------------------------
echo -e "\nDownloading OS Open UPRN data..."
curl -L "https://api.os.uk/downloads/v1/products/OpenUPRN/downloads?area=GB&format=CSV&redirect" -o uprn.zip

echo -e "\nExtracting ZIP archive..."
unzip -o uprn.zip >/dev/null
rm uprn.zip

# Secure extracted files (read/write for owner only)
chmod 600 *

# ------------------------------------------------------------------------------
# 3. Convert CSV to Parquet using DuckDB
# ------------------------------------------------------------------------------
csv_file=$(ls *.csv | head -n 1)
parquet_file="${csv_file%.*}.parquet"

echo -e "\nConverting CSV → Parquet using DuckDB..."
duckdb -c "
COPY (
  SELECT
    UPRN AS uprn,
    LATITUDE AS lat,
    LONGITUDE AS lon
  FROM read_csv_auto('$csv_file', sample_size=-1)
) TO '$parquet_file';
"

# ------------------------------------------------------------------------------
# 4. Display results
# ------------------------------------------------------------------------------
echo -e "\nConversion complete. Generated files:"
ls -lh

# ------------------------------------------------------------------------------
# 5. Return to root directory
# ------------------------------------------------------------------------------
cd ../../
echo -e "\nDone."

