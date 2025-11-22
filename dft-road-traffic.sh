#!/bin/bash
# ------------------------------------------------------------------------------
# Script: dft-road-traffic.sh
# Description:
#   Downloads DfT road traffic counts data,
#   processes raw counts and AADF datasets, converts to Parquet format.
# ------------------------------------------------------------------------------

# Strict mode: exit on error, undefined variables, and pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Prepare working directory
# ------------------------------------------------------------------------------
DATA_DIR="data/dft-road-traffic"
mkdir -p "$DATA_DIR"  # Create directory if it doesn't exist
cd "$DATA_DIR"  # Change to data directory

# ------------------------------------------------------------------------------
# 2. Download and process Raw Counts dataset
# ------------------------------------------------------------------------------
echo
echo "Downloading and extracting DfT Traffic Counts - Raw Counts dataset..."
wget -q https://storage.googleapis.com/dft-statistics/road-traffic/downloads/data-gov-uk/dft_traffic_counts_raw_counts.zip
unzip -o dft_traffic_counts_raw_counts.zip
rm *.zip
echo

# ------------------------------------------------------------------------------
# 3. Convert Raw Counts CSV to Parquet using DuckDB
# ------------------------------------------------------------------------------
echo "Processing Raw Counts data..."
for csv_file in *.csv; do
    if [ -f "$csv_file" ]; then
        filename=$(basename "$csv_file" .csv)
        parquet_file="${filename}.parquet"
        
        echo "Converting: $csv_file -> $parquet_file"
        
        duckdb -c "
        COPY (
          SELECT * 
          FROM read_csv_auto('$csv_file', nullstr=['NULL'])
        ) TO '$parquet_file' (FORMAT 'parquet');
        "
        break  # Only process first CSV file found
    fi
done

# ------------------------------------------------------------------------------
# 4. Download and process AADF dataset
# ------------------------------------------------------------------------------
echo
echo "Downloading and extracting DfT Traffic Counts - AADF dataset..."
wget -q https://storage.googleapis.com/dft-statistics/road-traffic/downloads/data-gov-uk/dft_traffic_counts_aadf.zip
unzip -o dft_traffic_counts_aadf.zip
rm *.zip
rm -rf __MACOSX
echo

# ------------------------------------------------------------------------------
# 5. Convert AADF CSV to Parquet using DuckDB
# ------------------------------------------------------------------------------
echo "Processing AADF data..."
for csv_file in *.csv; do
    if [ -f "$csv_file" ]; then
        filename=$(basename "$csv_file" .csv)
        parquet_file="${filename}.parquet"
        
        echo "Converting: $csv_file -> $parquet_file"
        
        duckdb -c "
        COPY (
          SELECT * 
          FROM read_csv_auto('$csv_file', nullstr=['NULL'])
        ) TO '$parquet_file' (FORMAT 'parquet');
        "
        break  # Only process first CSV file found
    fi
done

# ------------------------------------------------------------------------------
# 6. Organize and compress CSV files
# ------------------------------------------------------------------------------
echo
echo "Organizing and compressing CSV files..."
mkdir -p csv
mv *.csv csv/ 2>/dev/null || true  # Suppress error if no CSV files

# Check if pigz is available, otherwise use regular gzip
if command -v pigz &> /dev/null; then
    pigz -r csv/
else
    gzip -r csv/
fi

# ------------------------------------------------------------------------------
# 7. Display results
# ------------------------------------------------------------------------------
echo
echo "Conversion complete. Generated files:"
ls -lh  # List files with human-readable sizes

# ------------------------------------------------------------------------------
# 8. Return to project root directory
# ------------------------------------------------------------------------------
cd - >/dev/null  # Return to previous directory, suppress output
echo
echo "Done."
