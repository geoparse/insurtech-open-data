#!/bin/bash
# ------------------------------------------------------------------------------
# Script: os-open-names.sh
# Description:
#   Downloads OS Open Names dataset, converts to Parquet (EPSG:4326).
# ------------------------------------------------------------------------------

# Strict mode: exit on error, undefined variables, and pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Prepare working directory
# ------------------------------------------------------------------------------
DATA_DIR="data/os-open-names"
mkdir -p "$DATA_DIR"  # Create directory if it doesn't exist
cd "$DATA_DIR"  # Change to data directory

# ------------------------------------------------------------------------------
# 2. Download and extract the OS Open Names dataset
# ------------------------------------------------------------------------------
echo
echo "Downloading OS Open Names dataset..."

zip_file=os-open-names.zip
curl -L "https://api.os.uk/downloads/v1/products/OpenNames/downloads?area=GB&format=GeoPackage&redirect" -o $zip_file
unzip $zip_file
rm $zip_file

# Move and clean up extracted files
mv Data/* .
mv Doc/licence.txt .
rm -rf Data/ Doc/

# ------------------------------------------------------------------------------
# 3. Convert GeoPackage to Parquet using ogr2ogr
# ------------------------------------------------------------------------------
echo
echo "Converting GeoPackage to Parquet (EPSG:4326)..."

gpkg_file=$(ls *.gpkg)
parq_file=os-open-names.parquet

# Convert to Parquet with WGS84 (EPSG:4326) coordinate system
ogr2ogr "$parq_file" "$gpkg_file" -unsetFid -t_srs EPSG:4326 -makevalid

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
