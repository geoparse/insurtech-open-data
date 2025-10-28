

mkdir -p data/os-open-names
cd $_

curl -L "https://api.os.uk/downloads/v1/products/OpenNames/downloads?area=GB&format=GeoPackage&redirect" -o os-open-name.zip
unzip -o $_
rm $_

mv Data/* .
mv Doc/licence.txt .
rm -rf Data/ Doc/

gpkg_file=$(ls *.gpkg)
parq_file="${gpkg_file%.*}.parquet"

ogr2ogr os-open-names.parquet $gpkg_file -unsetFid  -t_srs EPSG:4326 -makevalid

# ------------------------------------------------------------------------------
# 4. Display results
# ------------------------------------------------------------------------------
echo
echo "Conversion complete. Generated files:"
ls -lh  # List files with human-readable sizes

# ------------------------------------------------------------
# Return to project root
# ------------------------------------------------------------
cd - >/dev/null  # Return to previous directory, suppress output
echo
echo "Done."
