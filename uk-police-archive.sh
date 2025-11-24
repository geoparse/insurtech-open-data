
mkdir -p data/police-archive
cd $_
wget https://data.police.uk/data/archive/latest.zip

unzip -o latest.zip
rm $_

for dir in */; do
  echo "Processing $dir..."
  (
    cd "$dir" || exit
    duckdb -c "COPY (SELECT * FROM read_csv_auto('*street*.csv', quote='\"')) TO 'street.parquet';"
    duckdb -c "COPY (SELECT * FROM read_csv_auto('*stop*.csv', quote='\"')) TO 'stop-and-search.parquet';"
    duckdb -c "COPY (SELECT * FROM read_csv_auto('*outcomes*.csv', quote='\"')) TO 'outcomes.parquet';"
    rm -f *.csv
  )
done

ls -lh
cd ../../
