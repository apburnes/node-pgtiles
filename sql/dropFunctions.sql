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
