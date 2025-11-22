#!/bin/bash

mkdir -p data/dft-road-traffic/
cd $_
wget https://storage.googleapis.com/dft-statistics/road-traffic/downloads/data-gov-uk/dft_traffic_counts_raw_counts.zip
unzip -o *.zip
rm *.zip

csv_file=$(ls *.csv)
parquet_file="${csv_file%.*}.parquet"

duckdb -c "COPY (SELECT * FROM read_csv_auto($csv_file, nullstr=['NULL'])) TO $parquet_file;"

mkdir -p csv
mv *.csv csv/

wget https://storage.googleapis.com/dft-statistics/road-traffic/downloads/data-gov-uk/dft_traffic_counts_aadf.zip
unzip -o *.zip
rm *.zip
rm -rf __MACOSX

csv_file=$(ls *.csv)
parquet_file="${csv_file%.*}.parquet"

duckdb -c "COPY (SELECT * FROM read_csv_auto($csv_file, nullstr=['NULL'])) TO $parquet_file;"

mv *.csv csv/
pigz -r csv/

ls -lh
cd ../../

