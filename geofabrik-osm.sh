#!/bin/bash
# ------------------------------------------------------------------------------
# Script: geofabrik-osm-extract.sh
# Description:
#   Downloads OSM data from Geofabrik and converts all layers to Parquet format.
# ------------------------------------------------------------------------------

# Strict mode: exit on error, undefined variables, and pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Prepare working directory
# ------------------------------------------------------------------------------
DATA_DIR="data/geofabrik-osm"  # Define main data directory path
REGION="europe"
COUNTRY="united-kingdom"
mkdir -p "$DATA_DIR/$COUNTRY"  # Create directory if it doesn't exist (with parents)
cd "$DATA_DIR/$COUNTRY"  # Change to country data directory

# ------------------------------------------------------------------------------
# 2. Download OSM data from Geofabrik
# ------------------------------------------------------------------------------
echo
echo "Downloading OSM data for $COUNTRY from Geofabrik..."

pbf_file="$COUNTRY-latest.osm.pbf"  # Define PBF filename
# Download the PBF file using wget
wget -q "https://download.geofabrik.de/$REGION/$pbf_file"

# ------------------------------------------------------------------------------
# 3. Extract and convert all layers to Parquet
# ------------------------------------------------------------------------------
echo
echo "Extracting OSM layers and converting to Parquet..."

# Extract layer names from PBF and convert each to Parquet format
# Pipeline breakdown:
# 1. `ogrinfo $pbf_file` - lists available layers (points, lines, multipolygons, etc.)
# 2. `cut -d: -f2` - removes layer numbers (e.g., "1: points" → " points")
# 3. `cut -d' ' -f2` - extracts actual layer names
# 4. `tail -n +3` - skips first two non-layer header lines
ogrinfo "$pbf_file" | cut -d: -f2 | cut -d' ' -f2 | tail -n +3 | while read layer; do 
    echo "Converting layer: $layer"
    ogr2ogr -f Parquet "${layer}.parquet" "$pbf_file" "$layer"
done

# ------------------------------------------------------------------------------
# 4. Display results
# ------------------------------------------------------------------------------
echo
echo "Extraction complete. Generated files:"
ls -lh  # List files with human-readable sizes

# ------------------------------------------------------------------------------
# 5. Return to project root directory
# ------------------------------------------------------------------------------
cd - >/dev/null  # Return to previous directory, suppress output
echo
echo "Done."
