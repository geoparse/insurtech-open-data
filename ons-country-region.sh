#!/usr/bin/env bash

# =====================================================================
# Script Name: ons-country-region.sh
# Description: 
#   Automates the conversion of ONS GeoPackage boundary files 
#   (countries and regions) into standardised Parquet format.
#   It detects whether each GeoPackage contains country or region data, 
#   applies the correct SQL projection, and renames the outputs 
#   consistently for further geospatial analysis.
# =====================================================================

set -euo pipefail

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

DATA_DIR="data/ons-country-region"  # Output directory for processed data
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

mkdir -p gpkg  # Directory to hold source GeoPackage files

echo "Copying downloaded GeoPackage files to $DATA_DIR/gpkg..."
cp ~/Downloads/Countries_*_Boundaries_UK_*.gpkg gpkg/  # Copy country boundaries
cp ~/Downloads/Regions_*_Boundaries_EN_*.gpkg gpkg/    # Copy region boundaries
echo

# ------------------------------------------------------------
# Convert GeoPackage files to Parquet
# ------------------------------------------------------------
echo "Converting GeoPackage files to Parquet format..."

# Loop through all .gpkg files and convert each to Parquet
for gpkg_file in gpkg/*.gpkg; do
    base_name=$(basename "$gpkg_file" .gpkg)
    echo "  Converting: $gpkg_file..."

    export CPL_LOG=/dev/null  # Suppress GDAL warnings and errors
    layer=$(ogrinfo "$gpkg_file" | grep Polygon | cut -d' ' -f2)  # Extract layer name
    
    # Detect whether the layer represents country or region data
    if ogrinfo "$gpkg_file" -al -so | tail -10 | cut -d: -f1 | grep -q CTRY; then
        sql_query="SELECT CTRY24CD as country_code, CTRY24NM as country, SHAPE as geometry FROM $layer"
    else
        sql_query="SELECT RGN24CD as region_code, RGN24NM as region, SHAPE as geometry FROM $layer"
    fi

    # Convert GeoPackage layer to Parquet with coordinate reprojection
    ogr2ogr \
      -f Parquet "${base_name}.parquet" \
      "$gpkg_file" \
      -t_srs EPSG:4326 \
      -sql "$sql_query" \
      -makevalid  # Ensure geometries are valid
done

echo "Conversion complete."
echo

# ------------------------------------------------------------
# Standardize Parquet filenames
# ------------------------------------------------------------
echo "Renaming Parquet files to standard names..."

# Rename country Parquet files
mv Countries_*_BFC_*.parquet uk_countries_bfc.parquet
mv Countries_*_BFE_*.parquet uk_countries_bfe.parquet
mv Countries_*_BGC_*.parquet uk_countries_bgc.parquet
mv Countries_*_BSC_*.parquet uk_countries_bsc.parquet
mv Countries_*_BUC_*.parquet uk_countries_buc.parquet
# Rename region Parquet files
mv Regions_*_BFC_*.parquet en_regions_bfc.parquet
mv Regions_*_BFE_*.parquet en_regions_bfe.parquet
mv Regions_*_BGC_*.parquet en_regions_bgc.parquet
mv Regions_*_BSC_*.parquet en_regions_bsc.parquet
mv Regions_*_BUC_*.parquet en_regions_buc.parquet

echo "All Parquet files ready in $DATA_DIR"
echo
ls -lh *.parquet

# ------------------------------------------------------------
# Return to project root
# ------------------------------------------------------------
cd - >/dev/null  # Go back silently to previous directory
