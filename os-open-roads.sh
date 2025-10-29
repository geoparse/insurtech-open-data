#!/bin/bash
# ------------------------------------------------------------------------------
# Script: os-open-roads.sh
# Description:
#   Downloads the latest OS Open Roads dataset,
#   converts GeoPackage layers to Parquet with coordinate transformation (EPSG:4326).
# ------------------------------------------------------------------------------

# Strict mode: exit on error, undefined variables, and pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Prepare working directory
# ------------------------------------------------------------------------------
DATA_DIR="data/os-open-roads"
mkdir -p "$DATA_DIR"  # Create directory if it doesn't exist
cd "$DATA_DIR"  # Change to data directory

# ------------------------------------------------------------------------------
# 2. Download and extract the OS Open Roads dataset
# ------------------------------------------------------------------------------
echo
echo "Downloading and Extracting the latest OS Open Roads dataset from Ordnance Survey..."
# Download the dataset from Ordnance Survey API
# -L follows redirects which are common with OS downloads
curl -L "https://api.os.uk/downloads/v1/products/OpenRoads/downloads?area=GB&format=GeoPackage&redirect" -o roads.zip
# Extract the zip file ($_ represents the last argument from previous command)
unzip -o $_
# Remove the zip file after extraction to save space
rm $_
echo

# ------------------------------------------------------------------------------
# 3. Reorganize extracted files
# ------------------------------------------------------------------------------
# Move all files from Data directory to current directory
mv Data/* .
# Move and rename licence file for easier access
mv Doc/licence.txt .
# Remove empty directories
rm -rf Data/ Doc/

# ------------------------------------------------------------------------------
# 4. Convert GeoPackage layers to Parquet using ogr2ogr
# ------------------------------------------------------------------------------
# Find the GeoPackage file (should be the only .gpkg file in directory)
gpkg_file=$(ls *.gpkg)

echo "Processing GeoPackage layers to Parquet format..."

# Extract layer names from GeoPackage and convert each to Parquet
# - ogrinfo: gets information about the GeoPackage
# - cut: extracts layer names from the output
# - tail: skips header lines
# - while read: processes each layer
ogrinfo "$gpkg_file" | cut -d: -f2 | cut -d' ' -f2 | tail -n +3 | while read layer; do 
    echo "  Converting layer: $layer"
    # Convert each layer to Parquet format
    # - ${layer}.parquet: output filename based on layer name
    # - $gpkg_file: input GeoPackage file
    # - $layer: specific layer to convert
    # - -unsetFid: don't include FID column in output
    # - -t_srs EPSG:4326: transform to WGS84 coordinate system (standard lat/lon)
    # - -makevalid: automatically fix any invalid geometries
    ogr2ogr "${layer}.parquet" "$gpkg_file" "$layer" -unsetFid -t_srs EPSG:4326 -makevalid
done

# ------------------------------------------------------------------------------
# 5. Display results
# ------------------------------------------------------------------------------
echo
echo "Conversion complete. Generated files:"
ls -lh  # List files with human-readable sizes (KB, MB, GB)

# ------------------------------------------------------------------------------
# 6. Return to project root directory
# ------------------------------------------------------------------------------
cd - >/dev/null  # Return to previous directory, suppress output with /dev/null
echo
echo "Done."
