#!/usr/bin/env bash

# =====================================================================
# Script Name: ons-country-region.sh
# Description:
#   Automates the conversion of ONS GeoPackage boundary files 
#   for UK countries and regions into a standardized Parquet format.
# Author: Abbas Eslami Kiasari
# =====================================================================

set -euo pipefail

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

DATA_DIR="data/ons-admin-country"  # Output directory for processed data
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

mkdir -p gpkg  # Directory to hold source GeoPackage files

echo "Copying downloaded GeoPackage files to $DATA_DIR/gpkg..."
cp ~/Downloads/Countries_*_Boundaries_UK_*.gpkg gpkg/  # Copy country boundaries
echo

# ------------------------------------------------------------
# Convert GeoPackage files to Parquet
# ------------------------------------------------------------
echo "Converting GeoPackage files to Parquet format..."

# Loop through all .gpkg files and convert each to Parquet
for gpkg_file in gpkg/*.gpkg; do
    base_name=$(basename "$gpkg_file" .gpkg)
    echo "  Converting: $gpkg_file..."

    layer=$(ogrinfo "$gpkg_file" | grep Polygon | cut -d' ' -f2)  # Extract layer name
    
    export CPL_LOG=/dev/null  # Suppress GDAL warnings and errors
    # Convert GeoPackage layer to Parquet with coordinate reprojection
    ogr2ogr \
      -f Parquet "${base_name}.parquet" \
      "$gpkg_file" \
      -t_srs EPSG:4326 \
      -sql "SELECT CTRY24CD as country_code, CTRY24NM as country, SHAPE as geometry FROM $layer" \
      -makevalid  # Ensure geometries are valid
done

echo "Conversion complete."
echo

# ------------------------------------------------------------
# Standardize Parquet filenames
# ------------------------------------------------------------

# Rename country Parquet files
mv Countries_*_BFC_*.parquet countries_bfc.parquet
mv Countries_*_BFE_*.parquet countries_bfe.parquet
mv Countries_*_BGC_*.parquet countries_bgc.parquet
mv Countries_*_BSC_*.parquet countries_bsc.parquet
mv Countries_*_BUC_*.parquet countries_buc.parquet

echo "All Parquet files ready in $DATA_DIR"
echo
ls -lh *.parquet

# ------------------------------------------------------------
# Return to project root
# ------------------------------------------------------------
cd - >/dev/null  # Go back silently to previous directory
