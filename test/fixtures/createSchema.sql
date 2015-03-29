CREATE TABLE IF NOT EXISTS map (
   zoom_level INTEGER,
   tile_column INTEGER,
   tile_row INTEGER,
   tile_id TEXT,
   grid_id TEXT
);

CREATE TABLE IF NOT EXISTS grid_key (
    grid_id TEXT,
    key_name TEXT
);

CREATE TABLE IF NOT EXISTS keymap (
    key_name TEXT,
    key_json TEXT
);

CREATE TABLE IF NOT EXISTS grid_utfgrid (
    grid_id TEXT,
    grid_utfgrid BYTEA
);

CREATE TABLE IF NOT EXISTS images (
    tile_data BYTEA,
    tile_id TEXT
);

CREATE TABLE IF NOT EXISTS metadata (
    name TEXT,
    value TEXT
);

CREATE TABLE IF NOT EXISTS geocoder_data (
    type TEXT,
    shard INTEGER,
    data BYTEA
);

CREATE UNIQUE INDEX map_index ON map (zoom_level, tile_column, tile_row);
CREATE UNIQUE INDEX grid_key_lookup ON grid_key (grid_id, key_name);
CREATE UNIQUE INDEX keymap_lookup ON keymap (key_name);
CREATE UNIQUE INDEX grid_utfgrid_lookup ON grid_utfgrid (grid_id);
CREATE UNIQUE INDEX images_id ON images (tile_id);
CREATE UNIQUE INDEX name ON metadata (name);
CREATE INDEX map_grid_id ON map (grid_id);
CREATE INDEX geocoder_type_index ON geocoder_data (type);
CREATE UNIQUE INDEX geocoder_shard_index ON geocoder_data (type, shard);

CREATE OR REPLACE VIEW tiles AS
    SELECT
        map.zoom_level AS zoom_level,
        map.tile_column AS tile_column,
        map.tile_row AS tile_row,
        images.tile_data AS tile_data
    FROM map
    JOIN images ON images.tile_id = map.tile_id;

CREATE OR REPLACE VIEW grids AS
    SELECT
        map.zoom_level AS zoom_level,
        map.tile_column AS tile_column,
        map.tile_row AS tile_row,
        grid_utfgrid.grid_utfgrid AS grid
    FROM map
    JOIN grid_utfgrid ON grid_utfgrid.grid_id = map.grid_id;

CREATE OR REPLACE VIEW grid_data AS
    SELECT
        map.zoom_level AS zoom_level,
        map.tile_column AS tile_column,
        map.tile_row AS tile_row,
        keymap.key_name AS key_name,
        keymap.key_json AS key_json
    FROM map
    JOIN grid_key ON map.grid_id = grid_key.grid_id
    JOIN keymap ON grid_key.key_name = keymap.key_name;

CREATE EXTENSION IF NOT EXISTS "postgis";

CREATE OR REPLACE FUNCTION CDB_XYZ_Resolution(z INTEGER)
RETURNS FLOAT8
AS $$
DECLARE
  earth_circumference FLOAT8;
  tile_size INTEGER;
  full_resolution FLOAT8;
BEGIN

  earth_circumference := 40075017;

  tile_size := 256;

  full_resolution := earth_circumference/tile_size;

  RETURN full_resolution / (power(2,z));

END
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT;

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

  tile_size := 256;

  initial_resolution := CDB_XYZ_Resolution(0);

  origin_shift := (initial_resolution * tile_size) / 2.0;

  pixres := initial_resolution / (power(2,z));

  tile_geo_size = tile_size * pixres;

  xmin := -origin_shift + x*tile_geo_size;
  xmax := -origin_shift + (x+1)*tile_geo_size;

  ymin := origin_shift - y*tile_geo_size;
  ymax := origin_shift - (y+1)*tile_geo_size;

  RETURN ST_MakeEnvelope(xmin, ymin, xmax, ymax, 3857);

END
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION public.z(scaledenominator numeric)
 RETURNS integer
 LANGUAGE plpgsql IMMUTABLE
AS $function$
begin
    if scaledenominator > 600000000 then
        return null;
    end if;
    return round(log(2,559082264.028/scaledenominator));
end;
$function$;

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

CREATE OR REPLACE FUNCTION public.linelabel(zoom numeric, label text, geometry geometry(Geometry, 900913))
 RETURNS boolean
 LANGUAGE plpgsql IMMUTABLE
AS $function$
begin
    if zoom > 20 or st_length(geometry) = 0 then
        return true;
    else
        return length(label) BETWEEN 1 AND st_length(geometry)/(2^(20-zoom));
    end if;
end;
$function$;

CREATE OR REPLACE FUNCTION public.topoint(geom geometry(Geometry, 900913))
 RETURNS geometry(Point, 900913)
 LANGUAGE plpgsql IMMUTABLE
AS $function$
begin
    if geometrytype(geom) = 'POINT' then
        return geom;
    elsif st_isempty(st_makevalid(geom)) then
        return NULL;
    else
        return st_pointonsurface(st_makevalid(geom));
    end if;
end;
$function$;

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

create or replace function zres(z float)
    returns float
    language plpgsql immutable
as $func$
begin
    return (40075016.6855785/(256*2^z));
end;
$func$;

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

create or replace function public.merc_length(geom geometry)
    returns numeric
    language plpgsql immutable as
$function$
begin
    return st_length(geom) * cos(radians(st_y(st_transform(st_centroid(geom),4326))));
end;
$function$;
