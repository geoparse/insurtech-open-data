#!/bin/bash
# ------------------------------------------------------------------------------
# Script: ons-postcode-directory.sh
# Description:
#   Downloads the latest ONS postcode and UPRN directories,
#   processes area codes, and creates combined area code dictionary.
# ------------------------------------------------------------------------------

export LC_ALL=C  # Set locale to C for consistent sorting and character handling

# Strict mode: exit on error, undefined variables, and pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Process Postcode Dataset
# ------------------------------------------------------------------------------
DATA_DIR="data/ons-area-codes/pcd"  # Define main data directory path
mkdir -p "$DATA_DIR"  # Create directory if it doesn't exist (with parents)
cd "$DATA_DIR"  # Change to data directory

DOC_DIR="Documents"  # Define subdirectory name for document files
AREA_DICT="ons-area-codes-pcd.csv"  # Output filename for area codes dictionary
TEMP_FILE=$(mktemp)  # Create temporary file for intermediate processing

echo
echo "Downloading and Extracting the ONS postcode documents from ArcGIS Hub..."
# Download the dataset from ArcGIS Hub
curl -L https://www.arcgis.com/sharing/rest/content/items/295e076b89b542e497e05632706ab429/data -o ons-postcode-directory.zip
# Extract the zip file ($_ represents the last argument from previous command - the zip filename)
unzip -q -o $_ "Documents/*" "User Guide/*"  # Extract only Documents and User Guide directories
# Remove the zip file after extraction to save space
rm *.zip

echo
echo "Extracting ONS area codes and names..."
# Find and process files matching the patterns for different geographic area types
for pattern in "CTRY*.csv" "RGN*.csv" "CTY*.csv" "LAD*.csv" "PFA*.csv" "MSOA*2021*.csv" "LSOA*2021*.csv" "NPARK*.csv"; do
    # Find files matching the pattern in the Documents directory
    for file in $DOC_DIR/$pattern; do
        echo "  $file"  # Print current file being processed
        # Extract first 2 columns, remove carriage returns, skip header line, remove empty lines and wrap both columns in quotes
        cut -d, -f1,2 "$file" | tr -d '\r' | tail -n +2 | grep -v '^,' | sed 's/^/"/; s/,/","/; s/$/"/' >> "$TEMP_FILE"
    done
done

echo '"L93000001","Channel Islands"' >> "$TEMP_FILE"
echo '"M83000003","Isle of Man"' >> "$TEMP_FILE"

# Sort and deduplicate (like merging dictionaries) - keep only first occurrence of each key
sort -t, -u -k1,1 "$TEMP_FILE" > "$AREA_DICT"

echo "Combined area dictionary created."
echo "  $AREA_DICT"

# Clean up temp file
rm $TEMP_FILE

# ------------------------------------------------------------------------------
# 2. Display results and move to next dataset
# ------------------------------------------------------------------------------
echo
echo "Postcode conversion complete. Generated files:"
ls -lh  # List files with human-readable sizes

# ------------------------------------------------------------------------------
# 3. Process UPRN Dataset
# ------------------------------------------------------------------------------
cd ..  # Go back to parent directory

DATA_DIR="uprn"  # Define main data directory path
mkdir -p "$DATA_DIR"  # Create directory if it doesn't exist (with parents)
cd "$DATA_DIR"  # Change to data directory

DOC_DIR="Documents"  # Define subdirectory name for document files
AREA_DICT="ons-area-codes-uprn.csv"  # Output filename for area codes dictionary
TEMP_FILE=$(mktemp)  # Create temporary file for intermediate processing

echo
echo "Downloading and Extracting the ONS UPRN documents from ArcGIS Hub..."
# Download the dataset from ArcGIS Hub
curl -L https://www.arcgis.com/sharing/rest/content/items/ad7564917fe94ae4aea6487321e36325/data -o ons-uprn-directory.zip
# Extract the zip file ($_ represents the last argument from previous command - the zip filename)
unzip -q -o $_ "Documents/*" "User Guide/*"  # Extract only Documents and User Guide directories
# Remove the zip file after extraction to save space
rm *.zip

echo
echo "Extracting ONS area codes and names..."
# Find and process files matching the patterns for different geographic area types
for pattern in "CTRY*.csv" "RGN*.csv" "CTY*.csv" "LAD*.csv" "PFA*.csv" "MSOA*2021*.csv" "LSOA*2021*.csv" "NPARK*.csv"; do
    # Find files matching the pattern in the Documents directory
    for file in $DOC_DIR/$pattern; do
        echo "  $file"  # Print current file being processed
        # Extract first 2 columns, remove carriage returns, skip header line, remove empty lines and wrap both columns in quotes
        cut -d, -f1,2 "$file" | tr -d '\r' | tail -n +2 | grep -v '^,' | sed 's/^/"/; s/,/","/; s/$/"/' >> "$TEMP_FILE"
    done
done

# Sort and deduplicate (like merging dictionaries) - keep only first occurrence of each key
sort -t, -u -k1,1 "$TEMP_FILE" > "$AREA_DICT"

echo "Combined area dictionary created."
echo "  $AREA_DICT"

# Clean up temp file
rm $TEMP_FILE

# ------------------------------------------------------------------------------
# 4. Display results and create combined file
# ------------------------------------------------------------------------------
echo
echo "UPRN conversion complete. Generated files:"
ls -lh  # List files with human-readable sizes

# ------------------------------------------------------------------------------
# 5. Create combined area codes file
# ------------------------------------------------------------------------------
cd ..  # Go back to parent directory

echo
echo "Creating combined area codes file..."
cat pcd/ons-area-codes-pcd.csv uprn/ons-area-codes-uprn.csv | sort -t, -u -k1,1 > ons-area-codes.csv

echo "Combined file created:"
echo "  ons-area-codes.csv"

# ------------------------------------------------------------------------------
# 6. Return to project root and display final message
# ------------------------------------------------------------------------------
cd - >/dev/null  # Return to previous directory, suppress output

echo
echo "Done. All area code files processed successfully."
