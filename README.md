# infrabel-opendata-to-pg
Copy tables from Infrabel open data to PostgreSQL/PostGIS

## Tools
You need to install the following tools:

* PostgreSQL
* PostGIS
* ogr2ogr (from GDAL)

I'm using a VM running on Debian 10 Buster, with PostgreSQL 12, PostGIS 3 and GDAL 2.4.

## Setup database
Install [PostgreSQL](https://postgresql.org) and [PostGIS](https://postgis.net) for your operating.

## Create a new database and enable PostGIS

With the user `postgres`, create a new user `pguser` (or another name) and make it owner of a new `opendata` database:

```sql
CREATE DATABASE opendata OWNER pguser;
```

Install PostGIS in a separate schema:

```sql
CREATE SCHEMA postgis;
ALTER SCHEMA postgis OWNER TO pguser;
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA postgis;
ALTER DATABASE opendata SET search_path TO 'public', 'postgis', '$user';
```

Connect as `pguser` and create a new `infrabel` schema:
```sql
CREATE SCHEMA infrabel AUTHORIZATION pguser;
```

Run `create_tables.sql` script:
```
sudo -u pguser psql -d opendata -f create_tables.sql
```

Run script
```
./import-infrabel-opendata.sh
```
