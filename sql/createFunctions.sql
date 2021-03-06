-- CartoDB functions https://raw.githubusercontent.com/CartoDB/cartodb-postgresql/9114d4e463c8664c1fb31e3bc538ce96c0dd0771/scripts-available/CDB_XYZ.sql

CREATE EXTENSION IF NOT EXISTS "postgis";

-- {
-- Return pixel resolution at the given zoom level
-- }{
CREATE OR REPLACE FUNCTION CDB_XYZ_Resolution(z INTEGER)
RETURNS FLOAT8
AS $$
DECLARE
  earth_circumference FLOAT8;
  tile_size INTEGER;
  full_resolution FLOAT8;
BEGIN

  -- Earth equatorial circumference in meters (according to wikipedia)
  earth_circumference := 40075017;

  -- Size of each tile in pixels (1:1 aspect ratio)
  tile_size := 256;

  full_resolution := earth_circumference/tile_size;

  RETURN full_resolution / (power(2,z));

END
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT;
-- }

-- {
-- Returns a polygon representing the bounding box of a given XYZ tile
--
-- SRID of the returned polygon is forceably 3857
--
-- }{
CREATE OR REPLACE FUNCTION CDB_XYZ_Extent(x INTEGER, y INTEGER, z INTEGER)
RETURNS GEOMETRY
AS $$
DECLARE
  origin_shift FLOAT8;
  initial_resolution FLOAT8;
  tile_geo_size FLOAT8;
  pixres FLOAT8;
  xmin FLOAT8;
  ymin FLOAT8;
  xmax FLOAT8;
  ymax FLOAT8;
  earth_circumference FLOAT8;
  tile_size INTEGER;
BEGIN

  -- Size of each tile in pixels (1:1 aspect ratio)
  tile_size := 256;

  initial_resolution := CDB_XYZ_Resolution(0);
  --RAISE DEBUG 'Initial resolution: %', initial_resolution;

  origin_shift := (initial_resolution * tile_size) / 2.0;
  -- RAISE DEBUG 'Origin shift  (after): %', origin_shift;

  pixres := initial_resolution / (power(2,z));
  --RAISE DEBUG 'Pixel resolution: %', pixres;

  tile_geo_size = tile_size * pixres;
  --RAISE DEBUG 'Tile_geo_size: %', tile_geo_size;

  xmin := -origin_shift + x*tile_geo_size;
  xmax := -origin_shift + (x+1)*tile_geo_size;
  --RAISE DEBUG 'xmin: %', xmin;
  --RAISE DEBUG 'xmax: %', xmax;

  ymin := origin_shift - y*tile_geo_size;
  ymax := origin_shift - (y+1)*tile_geo_size;
  --RAISE DEBUG 'ymin: %', ymin;
  --RAISE DEBUG 'ymax: %', ymax;

  RETURN ST_MakeEnvelope(xmin, ymin, xmax, ymax, 3857);

END
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT;
-- }


-- Mapbox Postgis Vector Tile Utilities https://github.com/mapbox/postgis-vt-util

---------------------------------------
-- converts mapnik's !scale_denominator! param to web mercator zoom
CREATE OR REPLACE FUNCTION public.z(scaledenominator numeric)
 RETURNS integer
 LANGUAGE plpgsql IMMUTABLE
AS $function$
begin
    -- Don't bother if the scale is larger than ~zoom level 0
    if scaledenominator > 600000000 then
        return null;
    end if;
    return round(log(2,559082264.028/scaledenominator));
end;
$function$;

---------------------------------------
-- early label placement helper. Snap geometry to a grid sized
-- for point places at the given zoom level and return a string "hash"
-- for deduping.
CREATE OR REPLACE FUNCTION public.labelgrid(geometry geometry(Geometry, 900913), grid_width numeric, pixel_width numeric)
 RETURNS text
 LANGUAGE plpgsql IMMUTABLE
AS $function$
begin
    if pixel_width = 0 then
        return 'null';
    end if;
    return st_astext(st_snaptogrid(
            geometry,
            grid_width/2*pixel_width,  -- x origin
            grid_width/2*pixel_width,  -- y origin
            grid_width*pixel_width,    -- x size
            grid_width*pixel_width     -- y size
    ));
end;
$function$;

---------------------------------------
-- early label placement filter -- determine whether a label text will
-- fit on a given line at a given zoom level.
CREATE OR REPLACE FUNCTION public.linelabel(zoom numeric, label text, geometry geometry(Geometry, 900913))
 RETURNS boolean
 LANGUAGE plpgsql IMMUTABLE
AS $function$
begin
    if zoom > 20 or st_length(geometry) = 0 then
        -- if length is 0 geom is (probably) a point; keep it
        return true;
    else
        return length(label) BETWEEN 1 AND st_length(geometry)/(2^(20-zoom));
    end if;
end;
$function$;

-- ---------------------------------------------------------------------
-- Helper to wrap st_pointonsurface, st_makevalid.
-- This is needed because of a st_pointonsurface bug in geos < 3.3.8 where
-- POLYGON EMPTY can pass through as a polygon geometry.
--
-- select st_geometrytype(st_pointonsurface(st_geomfromtext('POLYGON EMPTY')));
-- > ST_Polygon
CREATE OR REPLACE FUNCTION public.topoint(geom geometry(Geometry, 900913))
 RETURNS geometry(Point, 900913)
 LANGUAGE plpgsql IMMUTABLE
AS $function$
begin
    if geometrytype(geom) = 'POINT' then
        return geom;
    elsif st_isempty(st_makevalid(geom)) then
        -- This should not be necessary with Geos >= 3.3.7, but we're getting
        -- mystery MultiPoint objects from ST_MakeValid (or somewhere) when
        -- empty objects are input.
        return NULL;
    else
        return st_pointonsurface(st_makevalid(geom));
    end if;
end;
$function$;

-- ---------------------------------------------------------------------
-- Clean integer

create or replace function clean_int(i text)
    returns integer
    immutable
    language plpgsql as
$$
begin
    return cast(cast(i as float) as integer);
exception
    when invalid_text_representation then
        return null;
    when numeric_value_out_of_range then
        return null;
end;
$$;

-- ---------------------------------------------------------------------
-- Clean numeric

create or replace function clean_numeric(i text)
    returns numeric
    immutable
    language plpgsql as
$$
begin
    return cast(cast(i as float) as numeric);
exception
    when invalid_text_representation then
        return null;
    when numeric_value_out_of_range then
        return null;
end;
$$;

-- ---------------------------------------------------------------------
-- ZRES
-- Takes a web mercator zoom level and returns the pixel resolution for that
-- scale, assuming 256x256 pixel tiles. Non-integer zoom levels are accepted.
create or replace function zres(z float)
    returns float
    language plpgsql immutable
as $func$
begin
    return (40075016.6855785/(256*2^z));
end;
$func$;

-- ---------------------------------------------------------------------
-- MERC_BUFFER
-- Wrapper for ST_Buffer that adjusts distance by latitude to approximate
-- real-world measurements. Assumes input geometries are Web Mercator and
-- input distances are real-world meters. Accuracy decreases for larger
-- buffer distances and at extreme latitudes.
create or replace function public.merc_buffer(geom geometry, distance numeric)
    returns geometry
    language plpgsql immutable as
$function$
begin
    return st_buffer(
        geom,
        distance / cos(radians(st_y(st_transform(st_centroid(geom),4326))))
    );
end;
$function$;

-- ---------------------------------------------------------------------
-- MERC_DWITHIN
-- Wrapper for ST_DWithin that adjusts distance by latitude to approximate
-- real-world measurements. Assumes input geometries are Web Mercator and
-- input distances are real-world meters. Accuracy decreases for larger
-- distances and at extreme latitudes.
create or replace function public.merc_dwithin(
        geom1 geometry,
        geom2 geometry,
        distance numeric)
    returns boolean
    language plpgsql immutable as
$function$
begin
    return st_dwithin(
        geom1,
        geom2,
        distance / cos(radians(st_y(st_transform(st_centroid(geom1),4326))))
    );
end;
$function$;

-- ---------------------------------------------------------------------
-- MERC_LENGTH
-- Wrapper for ST_Length that adjusts distance by latitude to approximate
-- real-world measurements. Assumes input geometries are Web Mercator.
-- Accuracy decreases for larger y-axis ranges of the input.
create or replace function public.merc_length(geom geometry)
    returns numeric
    language plpgsql immutable as
$function$
begin
    return st_length(geom) * cos(radians(st_y(st_transform(st_centroid(geom),4326))));
end;
$function$;

