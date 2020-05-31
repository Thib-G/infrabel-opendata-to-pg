<?php
  header('Cache-control: max-age=300');
  header('Content-Type: application/json');
  include './secrets/connstring.php';

  $query = <<<SQL
SELECT
  json_build_object(
    'type', 'FeatureCollection',
    'features', json_agg(
      ST_AsGeoJSON(lrs.*, 'geom', 6)::json
    )
  ) AS geojson
FROM
  (
    SELECT
      tra_id,
      nr,
      trackcode,
      trackname,
      linecnum,
      linecalfa,
      ST_Transform(ST_Simplify(geom, 0.5), 4326) AS geom
    FROM
      infrabel.geotracks_lrs_mv
  ) AS lrs;
SQL;

  $result = pg_query($conn, $query) or die('Query failed: ' . pg_last_error());
  echo pg_fetch_assoc($result)['geojson'];
