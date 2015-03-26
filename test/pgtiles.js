'use strict';

var path = require('path');
var expect = require('chai').expect;
var PGTiles = require('../');
var readSql = require('../lib/readSql');

var connString = 'postgres://postgres:password@localhost:5432/test';

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
  {function_name: 'cdb_xyz_extent'}
];

var sqlVersion = 'SELECT SUM(10);';
var sqlTableSchema = 'SELECT table_name FROM information_schema.tables WHERE table_name = ANY(ARRAY[\'map\', \'grid_key\', \'keymap\', \'metadata\', \'grid_utfgrid\', \'images\', \'geocoder_data\'])';
var sqlFunctions = 'SELECT p.proname as function_name FROM pg_proc AS p WHERE p.proname = ANY(ARRAY[\'cdb_xyz_resolution\', \'cdb_xyz_extent\']);'
var sqlDrop = path.join(__dirname, './fixtures/dropSchema.sql');

describe('PGTiles', function() {
  afterEach(function(done) {
    readSql(sqlDrop, function(err, sql) {
      if (err) {
        return done(err);
      }

      var tiles = PGTiles(connString);
      tiles.query(sql, function(error) {
        done(error);
      });
    });
  });

  it('should succesfully connect and query the postgres database', function(done) {
    var tiles = PGTiles(connString);

    tiles.query(sqlVersion, function(err, result) {
      var rows = result.rows;
      expect(result).to.be.an('object');
      expect(rows).to.be.an('array');
      expect(rows[0]).to.have.deep.property('sum', '10');
      done(err);
    });
  });

  it('should succesfully create the pg table schema', function(done) {
    var tiles = PGTiles(connString);

    tiles.create(function(err, res) {
      if (err) {
        return done(err);
      }

      tiles.query(sqlTableSchema, function(error, result) {
        var rows = result.rows;
        expect(rows.length).to.equal(tables.length);
        expect(rows).to.deep.include.members(tables);
        done(error);
      });
    });
  });

  it('should succesfully create the pg functions', function(done) {
    var tiles = PGTiles(connString);

    tiles.create(function(err, res) {
      if (err) {
        return done(err);
      }

      tiles.query(sqlFunctions, function(error, result) {
        var rows = result.rows;
        expect(rows).to.deep.include.members(functions);
        done(error);
      });
    });
  });
});
