<?php
  error_reporting(E_ALL);
  header('Content-Type: application/json');
  include './secrets/connstring.php';

  $post_data = json_decode(file_get_contents('php://input'), true);

  $lat = $post_data['lat'];
  $lng = $post_data['lng'];

  $query = <<<SQL
-- Find the Kilometer Pole on the nearest track (with a max distance of 10000m)
-- from a known position ($lat, $lng)
-- and also return the coordinates of the projected point on the track axis
WITH pt_l72 (geom) AS
(
  -- as our track's geometries are in Lambert 72 coordinates, we first need
  -- to convert the GPS coordinates from WGS84 (EPSG:4326) to Lambert 72 (EPSG:31370)
  VALUES (ST_Transform(ST_SetSRID(ST_MakePoint($1, $2), 4326), 31370))
)
SELECT
  ST_AsGeoJSON(r.*) AS geojson
FROM
(
  SELECT
    g.trackcode,
    ROUND(ST_InterpolatePoint(g.geom, p.geom)) AS measure,
    ST_Distance(g.geom, p.geom) AS distance,
    ST_Transform(ST_ClosestPoint(g.geom, p.geom), 4326) AS geom
  FROM
    infrabel.geotracks_lrs_mv AS g
  JOIN
    pt_l72 AS p ON ST_DWithin(g.geom, p.geom, 10000.0)
  ORDER BY
    ST_Distance(g.geom, p.geom)
  LIMIT
    1
) AS r;
SQL;

  $result = pg_query_params($conn, $query, array($lng, $lat)) or die('Query failed: ' . pg_last_error());
  echo pg_fetch_assoc($result)['geojson'];
