#!/bin/bash

mkdir -p data/os-open-uprn
cd $_

curl -L "https://api.os.uk/downloads/v1/products/OpenUPRN/downloads?area=GB&format=CSV&redirect" -o uprn.zip
unzip -o $_
rm $_

chmod 600 *

csv_file=$(ls *.csv)
parquet_file="${csv_file%.*}.parquet"

duckdb -c "COPY (SELECT UPRN as uprn, LATITUDE as lat, LONGITUDE as lon FROM $csv_file) TO $parquet_file"

ls -lh
cd ../../
