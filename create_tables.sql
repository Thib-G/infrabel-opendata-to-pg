DROP MATERIALIZED VIEW IF EXISTS infrabel.kp_by_track_mv;

-- infrabel.geotracks definition

-- Drop table

DROP TABLE IF EXISTS infrabel.geotracks;

CREATE TABLE infrabel.geotracks (
  ogc_fid serial PRIMARY KEY,
  geom geometry(MultiLineString, 31370),
  status text,
  trackcode text,
  modifdate date,
  trackname text,
  linecnum int,
  geo_point_2d double precision[],
  linecalfa text,
  id int
);
CREATE INDEX ON infrabel.geotracks USING gist (geom);

-- infrabel.kp definition

-- Drop table

DROP TABLE IF EXISTS infrabel.kp;

CREATE TABLE infrabel.kp (
  ogc_fid serial PRIMARY KEY,
  geom geometry(MultiPoint, 31370) NULL,
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
  line_id int,
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
  id text,
  longnamedutch text
);
CREATE INDEX ON infrabel.points_op USING gist (geom);

-- infrabel.track_segments definition

-- Drop table

DROP TABLE IF EXISTS infrabel.track_segments;

CREATE TABLE infrabel.track_segments (
  ogc_fid serial PRIMARY KEY,
  geom geometry(MultiLineString, 31370),
  id int,
  geo_point_2d _float8
);
CREATE INDEX ON infrabel.track_segments USING gist (geom);


CREATE MATERIALIZED VIEW infrabel.kp_by_track_mv AS
SELECT
  ROW_NUMBER() OVER() AS auto_id,
  a.*,
  now() AS last_refresh
FROM
(
  SELECT DISTINCT ON (tra.id, kp.id)
     tra.trackcode,
     tra.status,
     tra.linecalfa,
     tra.linecnum,
     tra.id AS tra_id,
     kp.id AS kp_id,
     kp."name" AS kp_name,
     ST_ClosestPoint(tra.geom, kp.geom) AS geom
   FROM
     infrabel.kp AS kp
     JOIN infrabel.kp_by_line AS kbl ON kp.id = kbl.kp_id
     JOIN infrabel.geotracks AS tra ON kbl.line_id = tra.id
   ORDER BY
     tra.id, kp.id, ST_Distance(tra.geom, kp.geom)
) AS a;
CREATE UNIQUE INDEX ON infrabel.kp_by_track_mv (auto_id);
CREATE INDEX ON infrabel.kp_by_track_mv USING gist(geom);

