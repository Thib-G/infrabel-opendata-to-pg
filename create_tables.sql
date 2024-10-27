DROP MATERIALIZED VIEW IF EXISTS infrabel.geotracks_lrs_mv;
DROP MATERIALIZED VIEW IF EXISTS infrabel.geotracks_dumped_mv;
DROP MATERIALIZED VIEW IF EXISTS infrabel.kp_by_track_mv;

-- Drop table

DROP TABLE IF EXISTS infrabel.geopn;

CREATE TABLE infrabel.geopn (
	ogc_fid serial PRIMARY KEY,
	geom geometry(POINT, 31370),
	fld_naam_ramses text,
	fld_postcode_en_gemeente text,
	position_du_passage_a_niveau double precision[],
	fld_actief_passief text,
	fld_geo_x text,
	fld_geo_y text,
	type_pn text,
	type_lc text
);
CREATE INDEX ON infrabel.geopn USING gist (geom);

-- infrabel.geotracks definition

-- Drop table

DROP TABLE IF EXISTS infrabel.geotracks;

CREATE TABLE infrabel.geotracks (
  ogc_fid serial PRIMARY KEY,
  geom geometry(MultiLineString, 31370),
  status text,
  etat text,
  trackcode text,
  modifdate date,
  trackname text,
  linecnum int,
  geo_point_2d double precision[],
  linecalfa text,
  id int,
  exploitation text
);
CREATE INDEX ON infrabel.geotracks USING gist (geom);

-- infrabel.kp definition

-- Drop table

DROP TABLE IF EXISTS infrabel.kp;

CREATE TABLE infrabel.kp (
  ogc_fid serial PRIMARY KEY,
  geom geometry(MultiPointZ, 31370) NULL,
  y text,
  x text,
  id int4 NULL,
  "name" text,
  geo_point_2d double precision[]
);
CREATE INDEX kp_geom_geom_idx ON infrabel.kp USING gist (geom);

-- infrabel.kp_by_line definition

-- Drop table

DROP TABLE IF EXISTS infrabel.kp_by_line;

CREATE TABLE infrabel.kp_by_line (
  kp_id int,
  kp_name text,
  line_id int,
  line_name text,
  geo_point text,
  geo_shape text,
  PRIMARY KEY (kp_id, line_id)
);

-- infrabel.line_sections definition

-- Drop table

DROP TABLE IF EXISTS infrabel.line_sections;

CREATE TABLE infrabel.line_sections (
  ogc_fid serial PRIMARY KEY,
  geom geometry(LineString, 31370) NULL,
  ptcarfromname text,
  nrtracks int,
  symnamefrom text,
  gauge_nat text,
  c70 text,
  "label" text,
  ecs_maxtraincurrent int,
  symnameto text,
  mfrom int,
  ptcarto text,
  c400 text,
  p70 text,
  linecat_f text,
  ecs_voltfreq text,
  linecat_p text,
  p400 text,
  ptcartoname text,
  geo_point_2d double precision[],
  ls_id text,
  mto int,
  gauge text,
  ptcarfrom text,
  ecs_minwireheight float8,
  ecs_maxstandstillcurrent int
);
CREATE INDEX ON infrabel.line_sections USING gist (geom);

-- infrabel.points_op definition

-- Drop table

DROP TABLE IF EXISTS infrabel.points_op;

CREATE TABLE infrabel.points_op (
  ogc_fid serial PRIMARY KEY,
  geom geometry(Point, 31370),
  commercialshortnamedutch text,
  shortnamefrench text,
  classification text,
  commercialmiddlenamefrench text,
  commercialmiddlenamedutch text,
  taftapcode text,
  commercialshortnamefrench text,
  geo_point_2d _float8,
  symbolicname text,
  longnamefrench text,
  commerciallongnamedutch text,
  commerciallongnamefrench text,
  shortnamedutch text,
  ptcarid text,
  longnamedutch text,
  class_fr text,
  class_en text
);
CREATE INDEX ON infrabel.points_op USING gist (geom);

-- infrabel.track_segments definition

-- Drop table

DROP TABLE IF EXISTS infrabel.track_segments;

CREATE TABLE infrabel.track_segments (
  ogc_fid serial PRIMARY KEY,
  geom geometry(MultiLineStringZ, 31370),
  id int,
  geo_point_2d _float8
);
CREATE INDEX ON infrabel.track_segments USING gist (geom);

-- Join tracks and KPs and project KPs on track axis
CREATE MATERIALIZED VIEW infrabel.kp_by_track_mv AS
SELECT
  ROW_NUMBER() OVER() AS auto_id,
  a.*,
  now() AS last_refresh
FROM
(
  -- Get first track/KP combination, ordered by distance
  SELECT DISTINCT ON (tra.id, kp.id)
     tra.ogc_fid AS tra_ogc_fid,
     tra.trackcode,
     tra.status,
     tra.linecalfa,
     tra.linecnum,
     tra.id AS tra_id,
     kp.id AS kp_id,
     kp."name" AS kp_name,
     -- Snap KP to track axis
     ST_ClosestPoint(tra.geom, kp.geom)::geometry(Point, 31370) AS geom
   FROM
     infrabel.kp AS kp
     JOIN infrabel.kp_by_line AS kbl ON kp.id = kbl.kp_id
     JOIN infrabel.geotracks AS tra ON kbl.line_id = tra.id
   ORDER BY
     tra.id, kp.id, ST_Distance(tra.geom, kp.geom)
) AS a;
CREATE UNIQUE INDEX ON infrabel.kp_by_track_mv (auto_id);
CREATE INDEX ON infrabel.kp_by_track_mv USING gist(geom);

-- Merge track segments and then dump multilines to lines and path number
CREATE MATERIALIZED VIEW infrabel.geotracks_dumped_mv AS
SELECT
  c.id AS tra_id,
  (c.geom_dump).path[1] AS nr,
  (c.geom_dump).geom::geometry(LineString, 31370) AS geom
FROM 
(
  SELECT
    b.id,
    ST_Dump(b.geom) AS geom_dump
  FROM
  (
    SELECT
      a.id,
      ST_Multi(ST_LineMerge(ST_Collect(a.geom))) AS geom
    FROM
    (
      SELECT
        tra.id,
        (ST_Dump(tra.geom)).geom AS geom 
      FROM
        infrabel.geotracks AS tra
    ) AS a
    GROUP BY
      a.id
  ) AS b
) AS c;
CREATE UNIQUE INDEX ON infrabel.geotracks_dumped_mv (tra_id, nr);
CREATE INDEX ON infrabel.geotracks_dumped_mv USING gist(geom);

-- Generate Linear Referencing System from tracks and KPs
-- by adding a M-value to LineStrings				  
CREATE MATERIALIZED VIEW infrabel.geotracks_lrs_mv AS
WITH a AS (
-- Calculate fraction (from 0 to 1) of each KP on track
SELECT 
  tra.tra_id,
  tra.nr,
  kbt.kp_id,
  kbt.kp_name::int AS kp_name,
  ST_LineLocatePoint(tra.geom, kbt.geom) AS fraction,
  tra.geom
FROM 
  infrabel.geotracks_dumped_mv AS tra
  JOIN infrabel.kp_by_track_mv kbt
    ON kbt.tra_id = tra.tra_id
), b AS (
-- Add next KP and fraction for each row
SELECT
  a.tra_id,
  a.nr,
  a.kp_id AS kp_id_from,
  a.kp_name AS kp_name_from,
  a.fraction AS fraction_from,
  LEAD(a.kp_id) OVER w AS kp_id_to,
  LEAD(a.kp_name) OVER w AS kp_name_to,
  LEAD(a.fraction) OVER w AS fraction_to,
  a.geom
FROM
  a
WINDOW w AS (PARTITION BY a.tra_id, a.nr ORDER BY a.fraction)
ORDER BY
  a.tra_id,
  a.nr,
  a.fraction
), c AS (
-- 2) Add measures (KP from and KP to) for each segment
SELECT
  bb.tra_id,
  bb.nr,
  bb.kp_id_from,
  bb.kp_name_from,
  bb.fraction_from,
  bb.kp_id_to,
  bb.kp_name_to,
  bb.fraction_to,
  ST_AddMeasure(bb.geom, bb.kp_name_from * 1000.0, bb.kp_name_to * 1000.0) AS geom
FROM
(
  -- 1) Cut lines at fractions to generate segments of ~1 km
  SELECT
    b.tra_id,
    b.nr,
    b.kp_id_from,
    b.kp_name_from,
    b.fraction_from,
    b.kp_id_to,
    b.kp_name_to,
    b.fraction_to,
    ST_LineSubstring(geom, b.fraction_from, b.fraction_to) AS geom
  FROM
    b
  WHERE
    b.fraction_from < b.fraction_to
) AS bb
WHERE
  ST_GeometryType(bb.geom) = 'ST_LineString'
), d AS (
-- Convert lines into sets of MULTIPOINT M
SELECT
  c.tra_id,
  c.nr,
  ST_DumpPoints(c.geom) dump_pt
FROM 
  c
), e AS (
-- Explode MULTIPOINT M to list of vertices (POINT M)
SELECT
  d.tra_id,
  d.nr,
  (d.dump_pt).geom AS geom_pt,
  (d.dump_pt).path[1] AS path_pt
FROM d
)				       
-- Recreate lines from vertices, ordered by M and grouped by track id
SELECT
  e.tra_id,
  e.nr,
  geo.trackcode,
  geo.trackname,
  geo.linecnum,
  geo.linecalfa,
  now() AS last_refresh,
  ST_MakeLine(e.geom_pt ORDER BY ST_M(e.geom_pt))::geometry(LineStringM, 31370) AS geom
FROM
  e
JOIN
  (
    -- Join with distinct list of attributes
    SELECT DISTINCT
      id AS tra_id,
      trackcode,
      trackname,
      linecnum,
      linecalfa
    FROM
      infrabel.geotracks g
  ) geo ON e.tra_id = geo.tra_id
GROUP BY
  1, 2, 3, 4, 5, 6, 7;
CREATE UNIQUE INDEX ON infrabel.geotracks_lrs_mv (tra_id, nr);
CREATE INDEX ON infrabel.geotracks_lrs_mv USING gist(geom);
