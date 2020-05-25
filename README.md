# infrabel-opendata-to-pg
* Copies tables from Infrabel open data portal to PostgreSQL/PostGIS.
* Generates a Linear Referencing System from the geometry of the tracks and the positions of kilometer poles.

## Tools
You need to install the following tools:

* PostgreSQL
* PostGIS
* ogr2ogr (from GDAL)

I'm using a VM running on Debian 10 Buster, with PostgreSQL 12, PostGIS 3 and GDAL 2.4. Debian Buster comes with PostgreSQL 11. Use the [pgdg repo](https://wiki.postgresql.org/wiki/Apt) to get the latest PostgreSQL version for Debian (12 at the moment).

## Setup database
Install [PostgreSQL](https://postgresql.org) and [PostGIS](https://postgis.net) for your operating system.

Check if PostgreSQL is correctly installed:

```bash
~$ sudo -u postgres psql -A -c 'SELECT version();'
version
PostgreSQL 12.3 (Debian 12.3-1.pgdg100+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 8.3.0-6) 8.3.0, 64-bit
(1 row)
```

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

Check if PostGIS is correctly installed:
```bash
~$ psql -U pguser opendata -A -c 'SELECT postgis_full_version();'
postgis_full_version
POSTGIS="3.0.1 ec2a9aa" [EXTENSION] PGSQL="120" GEOS="3.7.1-CAPI-1.11.1 27a5e771" PROJ="Rel. 5.2.0, September 15th, 2018" LIBXML="2.9.4" LIBJSON="0.12.1" LIBPROTOBUF="1.3.1" WAGYU="0.4.3 (Internal)"
(1 row)
```

Connect as `pguser` and create a new `infrabel` schema:
```sql
CREATE SCHEMA infrabel AUTHORIZATION pguser;
```

Run `create_tables.sql` script inside `psql`:
```
psql -U pguser opendata -f create_tables.sql
```

Run script
```
./import-infrabel-opendata.sh
```