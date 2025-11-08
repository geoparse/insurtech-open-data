#!/usr/bin/env bash

# =====================================================================
# Script Name: ons-country-region.sh
# Description:
#   Automates the conversion of ONS GeoPackage boundary files 
#   for regions in England into a standardized Parquet format.
#
# Author: Abbas Eslami Kiasari
# =====================================================================

set -euo pipefail

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

DATA_DIR="data/ons-admin/region"  # Output directory for processed data
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

mkdir -p gpkg  # Directory to hold source GeoPackage files

echo "Copying downloaded GeoPackage files to $DATA_DIR/gpkg..."
cp ~/Downloads/Regions_*_Boundaries*.gpkg gpkg/  # Copy country boundaries
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
      -sql "SELECT RGN24CD as region_code, RGN24NM as region, SHAPE as geometry FROM $layer" \
      -makevalid  # Ensure geometries are valid
done

echo "Conversion complete."
echo

# ------------------------------------------------------------
# Standardize Parquet filenames
# ------------------------------------------------------------

# Rename country Parquet files
mv Regions_*_BFC_*.parquet regions_bfc.parquet
mv Regions_*_BFE_*.parquet regions_bfe.parquet
mv Regions_*_BGC_*.parquet regions_bgc.parquet
mv Regions_*_BSC_*.parquet regions_bsc.parquet
mv Regions_*_BUC_*.parquet regions_buc.parquet

echo "All Parquet files ready in $DATA_DIR"
echo
ls -lh *.parquet

# ------------------------------------------------------------
# Return to project root
# ------------------------------------------------------------
cd - >/dev/null  # Go back silently to previous directory
