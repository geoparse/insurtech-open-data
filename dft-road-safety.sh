#!/bin/bash
mkdir -p data/dft-road-safety/
cd $_

wget https://data.dft.gov.uk/road-accidents-safety-data/dft-road-casualty-statistics-collision-1979-latest-published-year.csv
csv_file=$(ls *.csv)
parquet_file="${csv_file%.*}.parquet"
duckdb -c "COPY (SELECT * FROM read_csv_auto('$csv_file', sample_size=-1)) TO '$parquet_file';"
rm $csv_file

wget https://data.dft.gov.uk/road-accidents-safety-data/dft-road-casualty-statistics-casualty-1979-latest-published-year.csv
csv_file=$(ls *.csv)
parquet_file="${csv_file%.*}.parquet"
duckdb -c "COPY (SELECT * FROM read_csv_auto('$csv_file', sample_size=-1)) TO '$parquet_file';"
rm $csv_file

wget https://data.dft.gov.uk/road-accidents-safety-data/dft-road-casualty-statistics-vehicle-1979-latest-published-year.csv
csv_file=$(ls *.csv)
parquet_file="${csv_file%.*}.parquet"
duckdb -c "COPY (SELECT * FROM read_csv_auto('$csv_file', sample_size=-1)) TO '$parquet_file';"
rm $csv_file

ls -lh
cd ../../
