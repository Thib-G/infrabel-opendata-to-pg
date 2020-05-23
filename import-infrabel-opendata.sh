# Settings
export pguser=pgthib
export db_name=opendata
# Geovoies https://opendata.infrabel.be/explore/dataset/geovoies
wget -nv -O geotracks.json "https://opendata.infrabel.be/explore/dataset/geovoies/download/?format=geojson&timezone=Europe/Berlin&lang=fr&epsg=31370"
psql -U $pguser -d $db_name -c 'TRUNCATE infrabel.geotracks;'
ogr2ogr -a_srs EPSG:31370 -f PGDump -nln geotracks -lco "GEOMETRY_NAME=geom" -lco "SCHEMA=infrabel" -lco "CREATE_SCHEMA=OFF" -lco "CREATE_TABLE=OFF" -append /vsistdout/ "geotracks.json" | psql -U $pguser -d $db_name -q -f -
# Bornes kilométriques https://opendata.infrabel.be/explore/dataset/bornes-kilometriques-sur-le-reseau
wget -nv -O kp.json "https://opendata.infrabel.be/explore/dataset/bornes-kilometriques-sur-le-reseau/download/?format=geojson&timezone=Europe/Berlin&lang=fr&epsg=31370"
psql -U $pguser -d $db_name -c 'TRUNCATE infrabel.kp;'
ogr2ogr -a_srs EPSG:31370 -f PGDump -nln kp -lco "GEOMETRY_NAME=geom" -lco "SCHEMA=infrabel" -lco "CREATE_SCHEMA=OFF" -lco "CREATE_TABLE=OFF" -append /vsistdout/ "kp.json" | psql -U $pguser -d $db_name -q -f -
# Sections de ligne https://opendata.infrabel.be/explore/dataset/segmentatie-volgens-de-eigenschappen-van-de-infrastructuur-en-de-exploitatiemoge
wget -nv -O line_sections.json "https://opendata.infrabel.be/explore/dataset/segmentatie-volgens-de-eigenschappen-van-de-infrastructuur-en-de-exploitatiemoge/download/?format=geojson&timezone=Europe/Berlin&lang=fr&epsg=31370"
psql -U $pguser -d $db_name -c 'TRUNCATE infrabel.line_sections;'
ogr2ogr -a_srs EPSG:31370 -f PGDump -nln line_sections -lco "GEOMETRY_NAME=geom" -lco "SCHEMA=infrabel" -lco "CREATE_SCHEMA=OFF" -lco "CREATE_TABLE=OFF" -append /vsistdout/ "line_sections.json" | psql -U $pguser -d $db_name -q -f -
# Points opérationnels https://opendata.infrabel.be/explore/dataset/points-operationnels-du-reseau
wget -nv -O points_op.json "https://opendata.infrabel.be/explore/dataset/points-operationnels-du-reseau/download/?format=geojson&timezone=Europe/Berlin&lang=fr&epsg=31370"
psql -U $pguser -d $db_name -c 'TRUNCATE infrabel.points_op;'
ogr2ogr -a_srs EPSG:31370 -f PGDump -nln points_op -lco "GEOMETRY_NAME=geom" -lco "SCHEMA=infrabel" -lco "CREATE_SCHEMA=OFF" -lco "CREATE_TABLE=OFF" -append /vsistdout/ "points_op.json" | psql -U $pguser -d $db_name -q -f -
# Segments de voies https://opendata.infrabel.be/explore/dataset/position-segments-voies
wget -nv -O track_segments.json "https://opendata.infrabel.be/explore/dataset/position-segments-voies/download/?format=geojson&timezone=Europe/Berlin&lang=fr&epsg=31370"
psql -U $pguser -d $db_name -c 'TRUNCATE infrabel.track_segments;'
ogr2ogr -a_srs EPSG:31370 -f PGDump -nln track_segments -lco "GEOMETRY_NAME=geom" -lco "SCHEMA=infrabel" -lco "CREATE_SCHEMA=OFF" -lco "CREATE_TABLE=OFF" -append /vsistdout/ "track_segments.json" | psql -U $pguser -d $db_name -q -f -
# Association BK et lignes https://opendata.infrabel.be/explore/dataset/association-des-bornes-kilometriques-et-des-voies
wget -nv -O kp_by_line.csv "https://opendata.infrabel.be/explore/dataset/association-des-bornes-kilometriques-et-des-voies/download/?format=csv&timezone=Europe/Berlin&lang=fr&use_labels_for_header=true&csv_separator=,"
psql -U $pguser -d $db_name -c 'TRUNCATE infrabel.kp_by_line;' -c "\copy infrabel.kp_by_line (kp_id, line_id) from 'kp_by_line.csv' csv header;"
# Mise à jour des vues matérialisées
psql -U $pguser -d $db_name -c 'REFRESH MATERIALIZED VIEW infrabel.kp_by_track_mv;'
