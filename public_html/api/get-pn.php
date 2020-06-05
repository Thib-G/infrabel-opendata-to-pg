<?php
  header('Cache-control: max-age=300');
  header('Content-Type: application/json');
  include './secrets/connstring.php';

  $query = <<<SQL
SELECT
  json_build_object(
    'type', 'FeatureCollection',
    'features', json_agg(
      ST_AsGeoJSON(pn.*, 'geom', 6)::json
    )
  ) AS geojson
FROM
  (
    SELECT
      ogc_fid,
      fld_naam_ramses,
      fld_postcode_en_gemeente,
      fld_actief_passief,
      ST_Transform(ST_Simplify(geom, 0.5), 4326) AS geom
    FROM
      infrabel.geopn
    ORDER BY
      fld_naam_ramses
  ) AS pn;
SQL;

  $result = pg_query($conn, $query) or die('Query failed: ' . pg_last_error());
  echo pg_fetch_assoc($result)['geojson'];
