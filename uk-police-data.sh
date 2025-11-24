#!/bin/bash
# ------------------------------------------------------------------------------
# Script: uk-police-data.sh
# Description:
#   Downloads UK police data archives (street crime, stop-and-search, outcomes),
#   converts CSV files to Parquet format for efficient analysis.
# ------------------------------------------------------------------------------

# Strict mode: exit on error, undefined variables, and pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Prepare working directory
# ------------------------------------------------------------------------------
DATA_DIR="data/uk-police-data"
mkdir -p "$DATA_DIR"  # Create directory if it doesn't exist
cd "$DATA_DIR"  # Change to data directory

# ------------------------------------------------------------------------------
# 2. Download latest police data archive
# ------------------------------------------------------------------------------
echo
echo "Downloading UK Police Data - Latest archive..."
wget -q --show-progress https://data.police.uk/data/archive/latest.zip

# ------------------------------------------------------------------------------
# 3. Extract archive and remove zip file
# ------------------------------------------------------------------------------
echo "  Extracting archive..."
unzip -q -o latest.zip
rm latest.zip

# ------------------------------------------------------------------------------
# 4. Process each police force directory
# ------------------------------------------------------------------------------
echo
echo "Processing police force data..."

for dir in */; do
    echo "  Processing: $dir"
    (
        cd "$dir" || exit
        
        # Create CSV directory for this police force
        mkdir -p csv
        
        # Convert Street Crime CSV to Parquet
        if ls *street*.csv 1> /dev/null 2>&1; then
            echo "    Converting street crime data..."
            duckdb -c "
            COPY (
                SELECT * 
                FROM read_csv_auto('*street*.csv', quote='\"', sample_size=-1)
            ) TO 'street.parquet' (FORMAT 'parquet');
            "
            mv *street*.csv csv/
        fi
        
        # Convert Stop and Search CSV to Parquet
        if ls *stop*.csv 1> /dev/null 2>&1; then
            echo "    Converting stop and search data..."
            duckdb -c "
            COPY (
                SELECT * 
                FROM read_csv_auto('*stop*.csv', quote='\"', sample_size=-1)
            ) TO 'stop-and-search.parquet' (FORMAT 'parquet');
            "
            mv *stop*.csv csv/
        fi
        
        # Convert Outcomes CSV to Parquet
        if ls *outcomes*.csv 1> /dev/null 2>&1; then
            echo "    Converting outcomes data..."
            duckdb -c "
            COPY (
                SELECT * 
                FROM read_csv_auto('*outcomes*.csv', quote='\"', sample_size=-1)
            ) TO 'outcomes.parquet' (FORMAT 'parquet');
            "
            mv *outcomes*.csv csv/
        fi
        
        # Compress CSV files
        echo "    Compressing CSV files..."
        if command -v pigz &> /dev/null; then
            pigz csv/*.csv 2>/dev/null || true
        else
            gzip csv/*.csv 2>/dev/null || true
        fi
    )
done

# ------------------------------------------------------------------------------
# 5. Display results
# ------------------------------------------------------------------------------
echo
echo "Conversion complete. Generated files by police force:"
ls -lh

# ------------------------------------------------------------------------------
# 6. Return to project root directory
# ------------------------------------------------------------------------------
cd - >/dev/null  # Return to previous directory, suppress output
echo
echo "Done."
