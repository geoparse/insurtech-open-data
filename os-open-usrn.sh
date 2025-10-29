#!/bin/bash
# ------------------------------------------------------------------------------
# Script: os-open-usrn.sh
# Description:
#   Downloads the latest OS Open USRN dataset,
#   converts GeoPackage to Parquet with coordinate transformation (EPSG:4326).
# ------------------------------------------------------------------------------

# Strict mode: exit on error, undefined variables, and pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Prepare working directory
# ------------------------------------------------------------------------------
DATA_DIR="data/os-open-usrn"
mkdir -p "$DATA_DIR"  # Create directory if it doesn't exist
cd "$DATA_DIR"  # Change to data directory

# ------------------------------------------------------------------------------
# 2. Download and extract the OS Open USRN dataset
# ------------------------------------------------------------------------------
echo
echo "Downloading and Extracting the latest OS Open USRN dataset from Ordnance Survey..."
# Download the dataset from Ordnance Survey API
# -L follows redirects which are common with OS downloads
curl -L "https://api.os.uk/downloads/v1/products/OpenUSRN/downloads?area=GB&format=GeoPackage&redirect" -o usrn.zip
# Extract the zip file ($_ represents the last argument from previous command)
unzip -o $_
# Remove the zip file after extraction to save space
rm $_
echo

# ------------------------------------------------------------------------------
# 3. Convert GeoPackage to Parquet using ogr2ogr
# ------------------------------------------------------------------------------
# Find the GeoPackage file (should be the only .gpkg file in directory)
gpkg_file=$(ls *.gpkg)
# Create Parquet filename by replacing .gpkg extension with .parquet
parquet_file="${gpkg_file%.*}.parquet"

echo "Processing: $gpkg_file -> $parquet_file"

# Convert GeoPackage to Parquet format using ogr2ogr
# - $parquet_file: output file
# - $gpkg_file: input GeoPackage file  
# - -dim 2: force 2D coordinates (ignore Z values)
# - -unsetFid: don't include FID column in output
# - -t_srs EPSG:4326: transform to WGS84 coordinate system (standard lat/lon)
# - -makevalid: automatically fix any invalid geometries
ogr2ogr "$parquet_file" "$gpkg_file" -dim 2 -unsetFid -t_srs EPSG:4326 -makevalid

# ------------------------------------------------------------------------------
# 4. Display results
# ------------------------------------------------------------------------------
echo
echo "Conversion complete. Generated files:"
ls -lh  # List files with human-readable sizes (KB, MB, GB)

# ------------------------------------------------------------------------------
# 5. Return to project root directory
# ------------------------------------------------------------------------------
cd - >/dev/null  # Return to previous directory, suppress output with /dev/null
echo
echo "Done."
