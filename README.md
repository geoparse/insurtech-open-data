# Open Data Preprocessing

This repository provides scripts for downloading, preprocessing and exporting open data into Parquet files.

---
# Prerequisites

## GDAL

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

## DuckDB
This repository uses `DuckDB`, a lightweight, in-process analytical database designed for fast querying of large datasets. Unlike traditional database servers, `DuckDB` runs directly inside your scripts or applications and can query files such as `CSV` and `Parquet` without requiring data to be imported first. It is often described as “SQLite for analytics” due to its simplicity and efficiency for analytical workloads. We use `DuckDB` to export files to the `Parquet` format.

```bash
brew install duckdb

```

# Open Datasets


<details>
<summary><h2>1. OS Open UPRN</h2></summary>

Source: [https://osdatahub.os.uk/downloads/open/OpenUPRN](https://osdatahub.os.uk/downloads/open/OpenUPRN)

Unique Property Reference Number (UPRN) is a unique identifier assigned to every addressable location in the United Kingdom, including residential and commercial properties, land parcels, and other structures such as bus shelters or community assets. Managed by Ordnance Survey, the UPRN acts as a consistent reference point across different datasets and systems, ensuring that information from local authorities, government bodies, and private organisations can be accurately linked to the same physical location. Because it is stable over the lifetime of the property or land parcel, the UPRN plays a vital role in data integration, geocoding, property analytics, and service delivery, helping organisations reduce duplication, improve accuracy, and make better evidence-based decisions.

You can download the latest UPRN dataset from [Ordnance Survey Data Hub](https://osdatahub.os.uk/downloads/open/OpenUPRN). Choose the `CSV` format, as it is smaller and faster to process than the `GeoPackage` version. 

```bash
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

```
</details>

<details>
<summary><h2>2. OS Open USRN</h2></summary>

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
<summary><h2>3. OS Open Roads</h2></summary>

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

```

</details>

<details>
<summary><h2>4. OpenStreetMap (OSM)</h2></summary>

Source: [https://download.geofabrik.de/](https://download.geofabrik.de/)

The following script is an automation pipeline to download and convert OpenStreetMap (OSM) data into Parquet files, layer by layer.

```bash
REGION='europe'
COUNTRY='united-kingdom'
mkdir -p data/osm/$COUNTRY
cd $_

wget https://download.geofabrik.de/$REGION/$COUNTRY-latest.osm.pbf

ogrinfo $COUNTRY-latest.osm.pbf | cut -d: -f2 | cut -d' ' -f2 | tail -n +3 | while read layer; do ogr2ogr ${layer}.parquet $COUNTRY-latest.osm.pbf $layer; done

ls -lh

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
<summary><h2>5. DfT Road Traffic</h2></summary>

Source: [https://roadtraffic.dft.gov.uk/downloads](https://roadtraffic.dft.gov.uk/downloads)

</details>


<details>
<summary><h2>6. DfT Road Safety</h2></summary>

Source: [https://www.data.gov.uk/dataset/road-accidents-safety-data](https://www.data.gov.uk/dataset/road-accidents-safety-data)

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
