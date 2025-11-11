#!/usr/bin/env bash

# =====================================================================
# Script Name: ons-census-lsoa.sh
# Description:
#   Automates the conversion of ONS GeoPackage boundary files 
#   for LSOAs into a standardized Parquet format.
#
# Author: Abbas Eslami Kiasari
# =====================================================================

set -euo pipefail

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

DATA_DIR="data/ons-census-boundaries/lsoa"  # Output directory for processed data
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

mkdir -p gpkg  # Directory to hold source GeoPackage files

echo "Copying downloaded GeoPackage files to $DATA_DIR/gpkg..."
cp ~/Downloads/Lower_layer*.gpkg gpkg/  # Copy country boundaries
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
      -sql "SELECT LSOA21CD as lsoa_code, LSOA21NM as lsoa, SHAPE as geometry FROM $layer" \
      -makevalid  # Ensure geometries are valid
done

echo "Conversion complete."
echo

# ------------------------------------------------------------
# Standardize Parquet filenames
# ------------------------------------------------------------

# Rename country Parquet files
mv Lower_*_BFC_*.parquet lsoa_bfc.parquet
mv Lower_*_BFE_*.parquet lsoa_bfe.parquet
mv Lower_*_BGC_*.parquet lsoa_bgc.parquet
mv Lower_*_BSC_*.parquet lsoa_bsc.parquet
#mv Lower_*_BUC_*.parquet lsoa_buc.parquet

echo "All Parquet files ready in $DATA_DIR"
echo
ls -lh *.parquet

# ------------------------------------------------------------
# Return to project root
# ------------------------------------------------------------
cd - >/dev/null  # Go back silently to previous directory
