#!/usr/bin/env bash

# =====================================================================
# Script Name: ons-admin-county.sh
# Description:
#   Automates the conversion of ONS GeoPackage boundary files 
#   for UK counties into a standardized Parquet format.
#
# Author: Abbas Eslami Kiasari
# =====================================================================

set -euo pipefail

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

DATA_DIR="data/ons-admin-boundaries/county-ua"  # Output directory for processed data
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

mkdir -p gpkg  # Directory to hold source GeoPackage files

echo "Copying downloaded GeoPackage files to $DATA_DIR/gpkg..."
cp ~/Downloads/Counties_*_Boundaries*.gpkg gpkg/  # Copy country boundaries
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
      -sql "SELECT
              CTYUA24CD AS county_ua_code,
              CTYUA24NM AS county_ua,
              SHAPE AS geometry,
              CASE
                  WHEN CTYUA24CD LIKE 'E06%' OR CTYUA24CD LIKE 'W06%' OR CTYUA24CD LIKE 'S12%' THEN 'Unitary Authority'
                  WHEN CTYUA24CD LIKE 'E08%' THEN 'Metropolitan Borough'
                  WHEN CTYUA24CD LIKE 'E09%' THEN 'London Borough'
                  WHEN CTYUA24CD LIKE 'E10%' THEN 'County'
                  WHEN CTYUA24CD LIKE 'N09%' THEN 'Local Government District'
              END AS area_type
              FROM $layer" \
      -makevalid  # Ensure geometries are valid
done

echo "Conversion complete."
echo

# ------------------------------------------------------------
# Standardize Parquet filenames
# ------------------------------------------------------------

# Rename country Parquet files
mv Counties_*_BFC_*.parquet counties_uas_bfc.parquet
mv Counties_*_BFE_*.parquet counties_uas_bfe.parquet
mv Counties_*_BGC_*.parquet counties_uas_bgc.parquet
mv Counties_*_BSC_*.parquet counties_uas_bsc.parquet
mv Counties_*_BUC_*.parquet counties_uas_buc.parquet

echo "All Parquet files ready in $DATA_DIR"
echo
ls -lh *.parquet

# ------------------------------------------------------------
# Return to project root
# ------------------------------------------------------------
cd - >/dev/null  # Go back silently to previous directory
