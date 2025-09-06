# Open Data Preprocessing

This repository provides scripts for downloading, preprocessing and exporting open data into Parquet files.

---
## Prerequisites

Before running the scripts in this repository, ensure that [GDAL](https://gdal.org/) is installed on your system.

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

```

```bash
ogrinfo --version

```

Both commands should return output similar to:

`GDAL 3.11.3 "Eganville", released 2025/07/12`

`GDAL` (Geospatial Data Abstraction Library) and `OGR` (OGR Simple Features Library) are essential tools for working with geospatial data. `GDAL` is designed for reading, writing, and processing raster geospatial data, such as satellite images and digital elevation models. It supports a variety of raster formats, including GeoTIFF, JPEG, PNG, and HDF5. On the other hand, `OGR` is specialized in handling vector geospatial data, including points, lines, and polygons, and supports formats like Shapefiles, GeoJSON, KML, PostGIS, and OSM PBF. 

A powerful feature within `GDAL/OGR` is the `ogr2ogr` command-line utility, which is dedicated to vector data manipulation and conversion. `ogr2ogr` allows users to convert vector data between formats (e.g., Shapefile to GeoJSON), filter and subset data using SQL-like queries, and reproject data to different coordinate reference systems (e.g., transforming WGS84 to a local `EPSG` code).

In summary, `GDAL` is tailored for raster data, `OGR` for vector data, and `ogr2ogr` provides versatile tools for converting, filtering, and reprojecting vector datasets.


You also need to install `duckdb` to be able to export files into `Parquet` format.

```bash
brew install duckdb

```

---
# UPRN
Unique Property Reference Number (UPRN) is a unique identifier assigned to every addressable location in the United Kingdom, including residential and commercial properties, land parcels, and other structures such as bus shelters or community assets. Managed by Ordnance Survey, the UPRN acts as a consistent reference point across different datasets and systems, ensuring that information from local authorities, government bodies, and private organisations can be accurately linked to the same physical location. Because it is stable over the lifetime of the property or land parcel, the UPRN plays a vital role in data integration, geocoding, property analytics, and service delivery, helping organisations reduce duplication, improve accuracy, and make better evidence-based decisions.

You can download the latest UPRN dataset from [Ordnance Survey Data Hub](https://osdatahub.os.uk/downloads/open/OpenUPRN). Choose the `CSV` format, as it is smaller and faster to process than the `GeoPackage` version. 

```bash
cd data/uprn

curl -L -o uprn.zip "https://api.os.uk/downloads/v1/products/OpenUPRN/downloads?area=GB&format=CSV&redirect"

unzip -o uprn.zip

rm uprn.zip

chmod 600 *

csv_file=$(ls *.csv)
parquet_file="${csv_file%.*}.parquet"

duckdb -c "COPY (SELECT UPRN as uprn, LATITUDE as lat, LONGITUDE as lon FROM $csv_file) TO $parquet_file"

```

---
# USRN

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


This following command converts the downloaded GeoPackage file to a Parquet file using `ogr2ogr`.

```bash
ogr2ogr osopenusrn_202509.parquet osopenusrn_202509.gpkg -dim 2 -unsetFid  -t_srs EPSG:4326 -makevalid

```
Here's what each part does:

* `ogr2ogr`: GDAL/OGR utility for converting geospatial data between formats
* `osopenusrn_202509.parquet`: Output file (Parquet format)
* `osopenusrn_202509.gpkg`: Input file (GeoPackage format)
* `-dim 2`: Forces 2D coordinates only (removes Z/elevation values)
* `-unsetFid`: Prevents FID column from being exported to output
* `-t_srs EPSG:4326`: Reprojects data to WGS84 (latitude/longitude)
* `-makevalid`: Attempts to fix invalid geometries

---
## License
This project is licensed under the MIT License. See `LICENSE` for details.

---
## Support
For issues or questions, feel free to create an issue in the repository or contact the maintainer.

---
## Contributing
Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.
