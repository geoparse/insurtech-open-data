# Open Data Preprocessing

This repository provides scripts for downloading, preprocessing and exporting open data into Parquet format.
It regularly ingests and serves the ONS and Ordnance Survey datasets.

---
# Prerequisites

<details>
<summary><h2>DuckDB</h2></summary>

This repository uses `DuckDB`, a lightweight, in-process analytical database designed for fast querying of large datasets. Unlike traditional database servers, `DuckDB` runs directly inside your scripts or applications and can query files such as `CSV` and `Parquet` without requiring data to be imported first. It is often described as “SQLite for analytics” due to its simplicity and efficiency for analytical workloads. We use `DuckDB` to export files to the `Parquet` format.

```bash
brew install duckdb

```
</details>


<details>
<summary><h2>GDAL</h2></summary>
Before running the scripts in this repository, ensure that [GDAL](https://gdal.org/) is installed on your system. `GDAL` (Geospatial Data Abstraction Library) and `OGR` (OGR Simple Features Library) are essential tools for working with geospatial data. `GDAL` is designed for reading, writing, and processing raster geospatial data, such as satellite images and digital elevation models. It supports a variety of raster formats, including GeoTIFF, JPEG, PNG, and HDF5. On the other hand, `OGR` is specialized in handling vector geospatial data, including points, lines, and polygons, and supports formats like Shapefiles, GeoJSON, KML, PostGIS, and OSM PBF. 

A powerful feature within `GDAL/OGR` is the `ogr2ogr` command-line utility, which is dedicated to vector data manipulation and conversion. `ogr2ogr` allows users to convert vector data between formats (e.g., Shapefile to GeoJSON), filter and subset data using SQL-like queries, and reproject data to different coordinate reference systems (e.g., transforming WGS84 to a local `EPSG` code).

In summary, `GDAL` is tailored for raster data, `OGR` for vector data, and `ogr2ogr` provides versatile tools for converting, filtering, and reprojecting vector datasets.


On Debian-based Systems:
```bash
sudo apt update
sudo apt install gdal-bin

```

On macOS:
```bash
brew update
brew install gdal

```

You can upgrade GDAL on your system if it is already installed.
```bash
brew upgrade gdal    # macOS
sudo apt install --only-upgrade gdal-bin    # Debian

```

After completing the installation, verify it by running the following commands:
```bash
gdalinfo --version
ogrinfo --version

```

Both commands should return output similar to:

`GDAL 3.11.3 "Eganville", released 2025/07/12`
</details>

# Open Datasets


<details>
<summary><h2>1. OS Open UPRN</h2></summary>

Source: [https://osdatahub.os.uk/downloads/open/OpenUPRN](https://osdatahub.os.uk/downloads/open/OpenUPRN)
Coverage: Great Britain

Unique Property Reference Number (UPRN) is a unique identifier assigned to every addressable location in the United Kingdom, including residential and commercial properties, land parcels, and other structures such as bus shelters or community assets. Managed by Ordnance Survey, the UPRN acts as a consistent reference point across different datasets and systems, ensuring that information from local authorities, government bodies, and private organisations can be accurately linked to the same physical location. Because it is stable over the lifetime of the property or land parcel, the UPRN plays a vital role in data integration, geocoding, property analytics, and service delivery, helping organisations reduce duplication, improve accuracy, and make better evidence-based decisions.

You can download the latest UPRN dataset from [Ordnance Survey Data Hub](https://osdatahub.os.uk/downloads/open/OpenUPRN). Choose the `CSV` format, as it is smaller and faster to process than the `GeoPackage` version. 

Alternatively, you can run the script directly:

```bash
./os-open-uprn.sh

```
This will download, process, and save the latest OS Open UPRN dataset as a `Parquet` file in the `data/os-open-uprn/` directory.
We convert the dataset to a `Parquet` file (using `DuckDB`) instead of a `GeoParquet` file (using `ogr2ogr`) because reading standard `Parquet` files with `pandas` is significantly faster than loading `GeoParquet` files with `geopandas` in Python.
</details>


<details>
<summary><h2>2. ONS Postcode Directory</h2></summary>

Source: [Online ONS Postcode Directory](https://www.data.gov.uk/dataset/4c105644-6071-45af-878c-6094a42df866/online-ons-postcode-directory-live1)


The following script provides an automated pipeline for downloading, cleansing, reprojecting, and converting postcode data into Parquet files.

```bash
./ons-postcode-directory.sh

curl -L https://open-geography-portalx-ons.hub.arcgis.com/api/download/v1/items/2ced9a3a2462432a92c31226e3cd3aa5/csv?layers=0 -o ons-postcode-dir.csv



```
The following sample shows the data structure stored in the Parquet file:





**Dataset Statistics (Unique Values):**
- `postcode`: ~1.79M
- `country_code`: 4
- 
- 
- `geometry`: ~1.73M

</details>



<details>
<summary><h2>2. OS Code-Point Open</h2></summary>

Source: [https://osdatahub.os.uk/downloads/open/CodePointOpen](https://osdatahub.os.uk/downloads/open/CodePointOpen)

`OS Code-Point® Open` is a free dataset from Ordnance Survey that provides a geographic coordinate for every postcode unit across Great Britain, covering over 1.7 million postcodes in England, Scotland, and Wales.
Each record includes the postcode, its precise location and the local authority code.
Released under the Open Government Licence, it can be freely used for both commercial and non-commercial purposes with proper attribution.

The following script provides an automated pipeline for downloading, cleansing, reprojecting, and converting postcode data into Parquet files.

```bash
./os-codepoint-open.sh

```
The following sample shows the data structure stored in the Parquet file:

| postcode | country_code | admin_district_code | admin_ward_code | geometry |
|----------|--------------|---------------------|-----------------|----------|
| AB10 1AB | Scotland | Aberdeen City | George St/Harbour Ward | POINT (-2.09692 57.14959) |
| AB10 1AF | Scotland | Aberdeen City | George St/Harbour Ward | POINT (-2.09692 57.14959) |
| AB10 1AG | Scotland | Aberdeen City | George St/Harbour Ward | POINT (-2.09700 57.14905) |
| AB10 1AH | Scotland | Aberdeen City | George St/Harbour Ward | POINT (-2.09692 57.14959) |
| AB10 1AL | Scotland | Aberdeen City | George St/Harbour Ward | POINT (-2.09530 57.14959) |

**Dataset Statistics (Unique Values):**
- `postcode`: ~1.74M
- `country_code`: 3
- `admin_district_code`: 350
- `admin_ward_code`: 7,524
- `geometry`: ~1.68M

</details>





<details>
<summary><h2>3. OS Open USRN</h2></summary>

Source: [https://osdatahub.os.uk/downloads/open/OpenUSRN](https://osdatahub.os.uk/downloads/open/OpenUSRN)

Unique Street Reference Number (USRN), is a nationally recognised identifier used in Great Britain to uniquely reference every street, including roads, footpaths, cycleways and alleys. It forms part of the national addressing system and is maintained through the [National Street Gazetteer](https://www.geoplace.co.uk/addresses-streets/street-data-and-services/national-street-gazetteer), which is compiled and updated by local authorities. Much like the Unique Property Reference Number (UPRN) identifies individual properties, the USRN ensures that each street has a consistent reference across different datasets and organisations. This makes it essential for activities such as managing streetworks permits, supporting navigation and transport planning, enabling emergency services, and integrating data across government and utility providers.

You can download the latest USRN dataset from [Ordnance Survey Data Hub](https://osdatahub.os.uk/downloads/open/OpenUSRN) as a `GeoPackage` file. 
The following command displays detailed information about the GeoPackage file's structure and contents.

```bash
ogrinfo -al -so osopenusrn_202509.gpkg

```

**Command Breakdown:**
* `ogrinfo`: GDAL/OGR utility for getting information about geospatial datasets
* `-al`: All layers - shows information about all layers in the dataset
* `-so`: Summary only - shows only the summary (no feature data)
* `osopenusrn_202509.gpkg`: The input GeoPackage file


This following commands downloads the GeoPackage file, process and export it into a Parquet file using `ogr2ogr`.

```bash
mkdir -p data/os-open-usrn
cd $_

curl -L "https://api.os.uk/downloads/v1/products/OpenUSRN/downloads?area=GB&format=GeoPackage&redirect" -o usrn.zip
unzip -o $_
rm $_

gpkg_file=$(ls *.gpkg)
parquet_file="${gpkg_file%.*}.parquet"

ogr2ogr $parquet_file $gpkg_file -dim 2 -unsetFid  -t_srs EPSG:4326 -makevalid

ls -lh
cd ../../

```
Here's what each part of the `ogr2ogr` does:

* `ogr2ogr`: GDAL/OGR utility for converting geospatial data between formats
* `osopenusrn_202509.parquet`: Output file (Parquet format)
* `osopenusrn_202509.gpkg`: Input file (GeoPackage format)
* `-dim 2`: Forces 2D coordinates only (removes Z/elevation values)
* `-unsetFid`: Prevents FID column from being exported to output
* `-t_srs EPSG:4326`: Reprojects data to WGS84 (latitude/longitude)
* `-makevalid`: Attempts to fix invalid geometries

</details>

<details>
<summary><h2>4. OS Open Roads</h2></summary>

Source: [https://osdatahub.os.uk/downloads/open/OpenRoads](https://osdatahub.os.uk/downloads/open/OpenRoads)


```bash

mkdir -p data/os-open-roads
cd $_

curl -L "https://api.os.uk/downloads/v1/products/OpenRoads/downloads?area=GB&format=GeoPackage&redirect" -o roads.zip
unzip -o $_
rm $_

mv Data/* .
mv Doc/licence.txt .
rm -rf Data/ Doc/

gpkg_file=$(ls *.gpkg)

ogrinfo $gpkg_file | cut -d: -f2 | cut -d' ' -f2 | tail -n +3 | while read layer; do ogr2ogr ${layer}.parquet $gpkg_file $layer -unsetFid  -t_srs EPSG:4326 -makevalid; done

ls -lh
cd ../../

```

</details>

<details>
<summary><h2>5. OpenStreetMap (OSM)</h2></summary>

Source: [https://download.geofabrik.de/](https://download.geofabrik.de/)

The following script is an automation pipeline to download and convert OpenStreetMap (OSM) data into Parquet files, layer by layer.

```bash
REGION='europe'
COUNTRY='united-kingdom'
mkdir -p data/geofabrik-osm/$COUNTRY
cd $_

wget https://download.geofabrik.de/$REGION/$COUNTRY-latest.osm.pbf

ogrinfo $COUNTRY-latest.osm.pbf | cut -d: -f2 | cut -d' ' -f2 | tail -n +3 | while read layer; do ogr2ogr ${layer}.parquet $COUNTRY-latest.osm.pbf $layer; done

ls -lh
cd ../../../

```

Here’s what each step does in the last command:

`ogrinfo $COUNTRY-latest.osm.pbf` prints available layers (e.g. `points`, `lines`, `multilinestrings`, `multipolygons`, `other_relations`).

* `cut -d: -f2` → removes the layer number (e.g. 1: points → points).

* `cut -d' ' -f2` → extracts the actual layer name.

* `tail -n +3` → skips the first two non-layer lines.

```bash
while read layer; do
    ogr2ogr ${layer}.parquet $COUNTRY-latest.osm.pbf $layer
done
```
For each layer name, `ogr2ogr` extracts it from the `.osm.pbf` and saves it as a separate Parquet file (e.g. points.parquet, lines.parquet, …) for easier analysis.

</details>

<details>
<summary><h2>6. DfT Road Traffic</h2></summary>

Source: [https://roadtraffic.dft.gov.uk/downloads](https://roadtraffic.dft.gov.uk/downloads)

```bash
mkdir -p data/dft-road-traffic/
cd $_
wget https://storage.googleapis.com/dft-statistics/road-traffic/downloads/data-gov-uk/dft_traffic_counts_raw_counts.zip
unzip -o *.zip
rm *.zip

csv_file=$(ls *.csv)
parquet_file="${csv_file%.*}.parquet"

duckdb -c "COPY (SELECT * FROM read_csv_auto($csv_file, nullstr=['NULL'])) TO $parquet_file;"
rm *.csv

wget https://storage.googleapis.com/dft-statistics/road-traffic/downloads/data-gov-uk/dft_traffic_counts_aadf.zip
unzip -o *.zip
rm *.zip
rm -rf __MACOSX

csv_file=$(ls *.csv)
parquet_file="${csv_file%.*}.parquet"

duckdb -c "COPY (SELECT * FROM read_csv_auto($csv_file, nullstr=['NULL'])) TO $parquet_file;"
rm *.csv

ls -lh
cd ../../

```
</details>


<details>
<summary><h2>7. DfT Road Safety</h2></summary>

Source: [https://www.data.gov.uk/dataset/road-accidents-safety-data](https://www.data.gov.uk/dataset/road-accidents-safety-data)

```bash
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

```
</details>


<details>
<summary><h2>8. Police Open Data</h2></summary>

Source: [https://data.police.uk/data/archive/](https://data.police.uk/data/archive/)

The following script automates the process of downloading the last three years of police data archives and converting them into Parquet files.

```bash
mkdir -p data/police
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

```

</details>


<details>
<summary><h2>9. ONS Income Data</h2></summary>

Source: [Income estimates for small areas, England and Wales - Office for National Statistics (ONS)](https://www.ons.gov.uk/employmentandlabourmarket/peopleinwork/earningsandworkinghours/datasets/smallareaincomeestimatesformiddlelayersuperoutputareasenglandandwales)

The Excel file on the above page contains separate sheets for:

* Total annual household income
* Net annual income
* Net income before housing costs
* Net income after housing costs

Data are provided at the `Middle Layer Super Output Area (MSOA)` level for England and Wales.
Each MSOA is represented by three values — the `lower confidence limit`, `mean estimate`, and `upper confidence limit` 
which together form a 95% confidence interval.
A `95% confidence interval` means that we can be 95% confident the true mean household income 
for each area lies between the lower and upper confidence limits. For further details, see the [Technical Report from Office for Natioanl Statistics, page 30.](https://www.ons.gov.uk/file?uri=/employmentandlabourmarket/peopleinwork/earningsandworkinghours/methodologies/smallareaincomeestimatesmodelbasedestimatesofthemeanhouseholdweeklyincomeformiddlelayersuperoutputareas201314technicalreport/householdincometechnicalreport.pdf)

The following script automates the process of downloading and converting income data into Parquet files, processing each sheet individually.

```bash
./ons-income.sh

```

</details>




<details>
<summary><h2>10. Output Area</h2></summary>

Source: [https://www.data.gov.uk/dataset/4a880a9b-b509-4a82-baf1-07e3ce104f4b/output-areas1](https://www.data.gov.uk/dataset/4a880a9b-b509-4a82-baf1-07e3ce104f4b/output-areas1)

Output Area Geography

`ons-output-area.sh` processes socio-economic data for different geographic layers in England and Wales, following the Office for National Statistics (ONS) spatial hierarchy. The smallest statistical building block is the `Census Output Area (OA)`, representing a compact group of households designed for detailed local analysis. `Lower-layer Super Output Areas (LSOA)` combine multiple OAs to ensure population stability over time, while `Middle-layer Super Output Areas (MSOA)` group several LSOAs to create larger, consistent geographic zones suitable for public reporting and policy analysis.

```bash

./ons-output-area.sh

```
</details>



<details>
<summary><h2>11. UK Countries and England Regions</h2></summary>

Source: [Countries](https://geoportal.statistics.gov.uk/search?q=BDY_CTRY%3BDEC_2024&sort=Title%7Ctitle%7Casc) and [Regions](https://geoportal.statistics.gov.uk/search?q=BDY_RGN%3BDEC_2024&sort=Title%7Ctitle%7Casc)

The Office for National Statistics (ONS) provides boundary data for the UK countries and the regions of England, available in multiple spatial resolutions and coastline treatments to balance accuracy and performance. Each boundary file includes a suffix such as `BFC`, `BFE`, `BGC`, `BSC`, or `BUC` that indicates both the detail level and whether the boundary is clipped to the coastline or includes the extent of the realm (i.e., offshore areas).
These options let you balance geometric accuracy with file size and performance, depending on your analysis or mapping needs.

Use full resolution versions (BFC/BFE) for analysis or precise overlays, and generalised versions (BGC/BSC/BUC) for visualisation, web mapping, or when handling large datasets.
Choose “clipped” versions when you only need land boundaries, or “extent of realm” when including sea/offshore territories is important.

| Code    | Meaning                                                       | Detail                                                                   |
| ------- | ------------------------------------------------------------- | ------------------------------------------------------------------------ |
| **BFE** | Boundary – Full resolution, *Extent of the Realm*             | Highest-detail geometry including offshore areas and islands.            |
| **BFC** | Boundary – Full resolution, *Clipped to coastline*            | Same high-detail boundary, but trimmed at the mean high-water coastline. |
| **BGC** | Boundary – Generalised (~20 m), *Clipped to coastline*        | Simplified geometry suitable for most mapping and display purposes.      |
| **BSC** | Boundary – Super-generalised (~200 m), *Clipped to coastline* | Coarser generalisation for lightweight, large-scale mapping.             |
| **BUC** | Boundary – Ultra-generalised (~500 m), *Clipped to coastline* | Smallest and simplest file size, least geometric detail.                 |

For process the files you need to download the `GeoPackage` files from the following pages for all spatial resolutions (`BFC`, `BFE`, `BGC`, `BSC`, and `BUC`).

[Countries](https://geoportal.statistics.gov.uk/search?q=BDY_CTRY%3BDEC_2024&sort=Title%7Ctitle%7Casc) and 
[Regions](https://geoportal.statistics.gov.uk/search?q=BDY_RGN%3BDEC_2024&sort=Title%7Ctitle%7Casc)

Make sure you downloaded 10 `GeoPackage` files and Then run the following scrips to process and to convert them to `Parquet` format.


```bash

./ons-country-region.sh

```

</details>


---
# License
For each dataset, please refer to the licence file located in the corresponding directory.

---
# Support
For issues or questions, feel free to create an issue in the repository or contact the maintainer.

---
# Contributing
Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.
