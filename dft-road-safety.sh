#!/bin/bash
# ------------------------------------------------------------------------------
# Script: dft-road-safety.sh
# Description:
#   Downloads DfT road safety data (collisions, casualties, vehicles),
#   converts CSV files to Parquet format for efficient analysis.
# ------------------------------------------------------------------------------

# Strict mode: exit on error, undefined variables, and pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Prepare working directory
# ------------------------------------------------------------------------------
DATA_DIR="data/dft-road-safety"
mkdir -p "$DATA_DIR"  # Create directory if it doesn't exist
cd "$DATA_DIR"  # Change to data directory
rm *.csv        # Delete csv files if they exist

# ------------------------------------------------------------------------------
# 2. Download and process Collision dataset
# ------------------------------------------------------------------------------
echo
echo "Downloading DfT Road Safety - Collision dataset..."
wget -q --show-progress https://data.dft.gov.uk/road-accidents-safety-data/dft-road-casualty-statistics-collision-1979-latest-published-year.csv

# Convert Collision CSV to Parquet using DuckDB
echo "  Processing Collision data..."
csv_file=$(ls *.csv | head -1)  # Get first CSV file
filename=$(basename "$csv_file" .csv)
parquet_file="${filename}.parquet"

echo "  Converting: $csv_file -> $parquet_file"
duckdb -c "
COPY (
  SELECT * 
  FROM read_csv_auto('$csv_file', sample_size=-1)
) TO '$parquet_file' (FORMAT 'parquet');
"

mkdir -p csv
mv "$csv_file" csv/ # Move original CSV after conversion

# ------------------------------------------------------------------------------
# 3. Download and process Casualty dataset
# ------------------------------------------------------------------------------
echo
echo "Downloading DfT Road Safety - Casualty dataset..."
wget -q --show-progress https://data.dft.gov.uk/road-accidents-safety-data/dft-road-casualty-statistics-casualty-1979-latest-published-year.csv

# Convert Casualty CSV to Parquet using DuckDB
echo "  Processing Casualty data..."
csv_file=$(ls *.csv | head -1)  # Get first CSV file
filename=$(basename "$csv_file" .csv)
parquet_file="${filename}.parquet"

echo "  Converting: $csv_file -> $parquet_file"
duckdb -c "
COPY (
  SELECT * 
  FROM read_csv_auto('$csv_file', sample_size=-1)
) TO '$parquet_file' (FORMAT 'parquet');
"
mv "$csv_file" csv/ # Move original CSV after conversion

# ------------------------------------------------------------------------------
# 4. Download and process Vehicle dataset
# ------------------------------------------------------------------------------
echo
echo "Downloading DfT Road Safety - Vehicle dataset..."
wget -q --show-progress https://data.dft.gov.uk/road-accidents-safety-data/dft-road-casualty-statistics-vehicle-1979-latest-published-year.csv

# Convert Vehicle CSV to Parquet using DuckDB
echo "  Processing Vehicle data..."
csv_file=$(ls *.csv | head -1)  # Get first CSV file
filename=$(basename "$csv_file" .csv)
parquet_file="${filename}.parquet"

echo "  Converting: $csv_file -> $parquet_file"
duckdb -c "
COPY (
  SELECT * 
  FROM read_csv_auto('$csv_file', sample_size=-1)
) TO '$parquet_file' (FORMAT 'parquet');
"
mv "$csv_file" csv/ # Move original CSV after conversion

# Check if pigz is available, otherwise use regular gzip
if command -v pigz &> /dev/null; then
    pigz -r csv/
else
    gzip -r csv/
fi

# ------------------------------------------------------------------------------
# 5. Display results
# ------------------------------------------------------------------------------
echo
echo "Conversion complete. Generated files:"
ls -lh  # List files with human-readable sizes

# ------------------------------------------------------------------------------
# 6. Return to project root directory
# ------------------------------------------------------------------------------
cd - >/dev/null  # Return to previous directory, suppress output
echo
echo "Done."
