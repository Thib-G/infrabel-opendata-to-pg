# Settings
pguser=pgthib
db_name=opendata
# Change directory to script path
script_dir=$(dirname $0)
echo $script_dir
cd $script_dir
# GeoPN https://opendata.infrabel.be/explore/dataset/geoow
wget -nv -O geopn.json "https://opendata.infrabel.be/explore/dataset/geoow/download/?format=geojson&timezone=Europe/Berlin&lang=fr&epsg=31370"
psql -U $pguser -d $db_name -c 'TRUNCATE infrabel.geopn;'
ogr2ogr -a_srs EPSG:31370 -f PGDump -nln geopn -lco "GEOMETRY_NAME=geom" -lco "SCHEMA=infrabel" -lco "CREATE_SCHEMA=OFF" -lco "CREATE_TABLE=OFF" -append /vsistdout/ "geopn.json" | psql -U $pguser -d $db_name -q -f -
# Geovoies https://opendata.infrabel.be/explore/dataset/geosporen
wget -nv -O geotracks.json "https://opendata.infrabel.be/explore/dataset/geosporen/download/?format=geojson&timezone=Europe/Berlin&lang=fr&epsg=31370"
psql -U $pguser -d $db_name -c 'TRUNCATE infrabel.geotracks;'
ogr2ogr -where "OGR_GEOMETRY='LineString' OR OGR_GEOMETRY='MultiLineString'" -a_srs EPSG:31370 -f PGDump -nln geotracks -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=geom" -lco "SCHEMA=infrabel" -lco "CREATE_SCHEMA=OFF" -lco "CREATE_TABLE=OFF" -append /vsistdout/ "geotracks.json" | psql -U $pguser -d $db_name -q -f -
# Bornes kilométriques https://opendata.infrabel.be/explore/dataset/kilometerpalen-op-het-netwerk
wget -nv -O kp.json "https://opendata.infrabel.be/explore/dataset/kilometerpalen-op-het-netwerk/download/?format=geojson&timezone=Europe/Berlin&lang=fr&epsg=31370"
psql -U $pguser -d $db_name -c 'TRUNCATE infrabel.kp;'
ogr2ogr -a_srs EPSG:31370 -f PGDump -nln kp -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=geom" -lco "SCHEMA=infrabel" -lco "CREATE_SCHEMA=OFF" -lco "CREATE_TABLE=OFF" -append /vsistdout/ "kp.json" | psql -U $pguser -d $db_name -q -f -
# Sections de ligne https://opendata.infrabel.be/explore/dataset/lijnsecties
wget -nv -O line_sections.json "https://opendata.infrabel.be/explore/dataset/lijnsecties/download/?format=geojson&timezone=Europe/Berlin&lang=fr&epsg=31370"
psql -U $pguser -d $db_name -c 'TRUNCATE infrabel.line_sections;'
ogr2ogr -a_srs EPSG:31370 -f PGDump -nln line_sections -lco "GEOMETRY_NAME=geom" -lco "SCHEMA=infrabel" -lco "CREATE_SCHEMA=OFF" -lco "CREATE_TABLE=OFF" -append /vsistdout/ "line_sections.json" | psql -U $pguser -d $db_name -q -f -
# Points opérationnels https://opendata.infrabel.be/explore/dataset/operationele-punten-van-het-newterk
wget -nv -O points_op.json "https://opendata.infrabel.be/explore/dataset/operationele-punten-van-het-newterk/download/?format=geojson&timezone=Europe/Berlin&lang=fr&epsg=31370"
psql -U $pguser -d $db_name -c 'TRUNCATE infrabel.points_op;'
ogr2ogr -a_srs EPSG:31370 -f PGDump -nln points_op -lco "GEOMETRY_NAME=geom" -lco "SCHEMA=infrabel" -lco "CREATE_SCHEMA=OFF" -lco "CREATE_TABLE=OFF" -append /vsistdout/ "points_op.json" | psql -U $pguser -d $db_name -q -f -
# Segments de voies https://opendata.infrabel.be/explore/dataset/geografische-positie-van-alle-spoorsegmenten
wget -nv -O track_segments.json "https://opendata.infrabel.be/explore/dataset/geografische-positie-van-alle-spoorsegmenten/download/?format=geojson&timezone=Europe/Berlin&lang=fr&epsg=31370"
psql -U $pguser -d $db_name -c 'TRUNCATE infrabel.track_segments;'
ogr2ogr -a_srs EPSG:31370 -f PGDump -nln track_segments -nlt PROMOTE_TO_MULTI -lco "GEOMETRY_NAME=geom" -lco "SCHEMA=infrabel" -lco "CREATE_SCHEMA=OFF" -lco "CREATE_TABLE=OFF" -append /vsistdout/ "track_segments.json" | psql -U $pguser -d $db_name -q -f -
# Association BK et lignes https://opendata.infrabel.be/explore/dataset/relatie-tussen-kilometerpalen-en-lijnen
wget -nv -O kp_by_line.csv "https://opendata.infrabel.be/explore/dataset/relatie-tussen-kilometerpalen-en-lijnen/download/?format=csv&timezone=Europe/Berlin&lang=fr&use_labels_for_header=true&csv_separator=,"
psql -U $pguser -d $db_name \
	-c 'TRUNCATE infrabel.kp_by_line;' \
	-c "\copy infrabel.kp_by_line (kp_id, line_id) from 'kp_by_line.csv' csv header;"
# Mise à jour des vues matérialisées
psql -U $pguser -d $db_name \
	-c 'REFRESH MATERIALIZED VIEW infrabel.kp_by_track_mv;' \
	-c 'REFRESH MATERIALIZED VIEW infrabel.geotracks_dumped_mv;' \
	-c 'REFRESH MATERIALIZED VIEW infrabel.geotracks_lrs_mv;'
