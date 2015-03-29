'use strict';

var tables = [
  {table_name: 'map'},
  {table_name: 'grid_key'},
  {table_name: 'keymap'},
  {table_name: 'grid_utfgrid'},
  {table_name: 'images'},
  {table_name: 'metadata'},
  {table_name: 'geocoder_data'}
];

var functions = [
  {function_name: 'cdb_xyz_resolution'},
  {function_name: 'cdb_xyz_extent'},
  {function_name: 'z'},
  {function_name: 'labelgrid'},
  {function_name: 'linelabel'},
  {function_name: 'topoint'},
  {function_name: 'clean_int'},
  {function_name: 'clean_numeric'},
  {function_name: 'zres'},
  {function_name: 'merc_buffer'},
  {function_name: 'merc_dwithin'},
  {function_name: 'merc_length'}
];

module.exports = {
  tables: tables,
  functions: functions
};
