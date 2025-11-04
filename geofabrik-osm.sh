#!/bin/bash
# ------------------------------------------------------------------------------
# Script: geofabrik-osm-extract.sh
# Description:
#   Downloads OSM data from Geofabrik and converts all layers to Parquet format.
# ------------------------------------------------------------------------------

# Strict mode: exit on error, undefined variables, and pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Validate input parameters
# ------------------------------------------------------------------------------
if [ $# -ne 2 ]; then
    echo "Error: Incorrect number of parameters"
    echo "Usage: $0 <region> <country>"
    echo "Example: $0 europe united-kingdom"
    echo "Check https://download.geofabrik.de/ for available regions and countries"
    exit 1
fi

REGION="$1"
COUNTRY="$2"

# ------------------------------------------------------------------------------
# 2. Prepare working directory
# ------------------------------------------------------------------------------
DATA_DIR="data/geofabrik-osm"  # Define main data directory path
mkdir -p "$DATA_DIR/$COUNTRY"  # Create directory if it doesn't exist (with parents)
cd "$DATA_DIR/$COUNTRY"  # Change to country data directory

# ------------------------------------------------------------------------------
# 3. Download OSM data from Geofabrik
# ------------------------------------------------------------------------------
echo
echo "Downloading OSM data for $COUNTRY ($REGION) from Geofabrik..."

pbf_file="$COUNTRY-latest.osm.pbf"  # Define PBF filename
# Download the PBF file using wget
curl -L -o "$pbf_file" "https://download.geofabrik.de/$REGION/$pbf_file"

# Check if file is HTML (error page) instead of PBF
if file "$pbf_file" | grep -q "HTML"; then
    echo "Country '$COUNTRY' does not exist in region '$REGION'"
    cd ..
    rm -rf "$COUNTRY"
    exit 1
fi

# Check if download was successful
if [ ! -f "$pbf_file" ]; then
    echo "Error: Failed to download $pbf_file"
    echo "Please check if the region/country combination exists: $REGION/$COUNTRY"
    echo "Visit https://download.geofabrik.de/$REGION.html for available countries"
    exit 1
fi

# ------------------------------------------------------------------------------
# 4. Extract and convert all layers to Parquet
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
    # Convert each OSM layer to Parquet format
    ogr2ogr -f Parquet "${layer}.parquet" "$pbf_file" "$layer"
done

# ------------------------------------------------------------------------------
# 5. Display results
# ------------------------------------------------------------------------------
echo
echo "Extraction complete. Generated files:"
ls -lh  # List files with human-readable sizes

# ------------------------------------------------------------------------------
# 6. Return to project root directory
# ------------------------------------------------------------------------------
cd - >/dev/null  # Return to previous directory, suppress output
echo
echo "Done."
