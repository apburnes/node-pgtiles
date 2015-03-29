DROP VIEW IF EXISTS tiles CASCADE;
DROP VIEW IF EXISTS grids CASCADE;
DROP VIEW IF EXISTS grid_data CASCADE;

DROP INDEX IF EXISTS map_index;
DROP INDEX IF EXISTS grid_key_lookup;
DROP INDEX IF EXISTS keymap_lookup;
DROP INDEX IF EXISTS grid_utfgrid_lookup;
DROP INDEX IF EXISTS images_id;
DROP INDEX IF EXISTS name;
DROP INDEX IF EXISTS map_grid_id;
DROP INDEX IF EXISTS geocoder_type_index;
DROP INDEX IF EXISTS geocoder_shard_index;

DROP TABLE IF EXISTS map CASCADE;
DROP TABLE IF EXISTS grid_key CASCADE;
DROP TABLE IF EXISTS keymap CASCADE;
DROP TABLE IF EXISTS grid_utfgrid CASCADE;
DROP TABLE IF EXISTS images CASCADE;
DROP TABLE IF EXISTS metadata CASCADE;
DROP TABLE IF EXISTS geocoder_data CASCADE;

DROP FUNCTION IF EXISTS CDB_XYZ_Resolution(z INTEGER) CASCADE;
DROP FUNCTION IF EXISTS CDB_XYZ_Extent(x INTEGER, y INTEGER, z INTEGER) CASCADE;

DROP FUNCTION IF EXISTS public.z(scaledenominator numeric) CASCADE;
DROP FUNCTION IF EXISTS public.labelgrid(geometry geometry(Geometry, 900913), grid_width numeric, pixel_width numeric) CASCADE;
DROP FUNCTION IF EXISTS public.linelabel(zoom numeric, label text, geometry geometry(Geometry, 900913)) CASCADE;
DROP FUNCTION IF EXISTS public.topoint(geom geometry(Geometry, 900913)) CASCADE;
DROP FUNCTION IF EXISTS public.clean_int(i text) CASCADE;
DROP FUNCTION IF EXISTS public.clean_numeric(i text) CASCADE;
DROP FUNCTION IF EXISTS public.zres(z float) CASCADE;
DROP FUNCTION IF EXISTS public.merc_buffer(geom geometry, distance numeric) CASCADE;
DROP FUNCTION IF EXISTS public.merc_dwithin(
    geom1 geometry,
    geom2 geometry,
    distance numeric) CASCADE;
DROP FUNCTION IF EXISTS public.merc_length(geom geometry) CASCADE;

