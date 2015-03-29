'use strict';

var path = require('path');
var expect = require('chai').expect;
var PGTiles = require('../');
var readSql = require('../lib/readSql');

var connString = 'postgres://postgres:password@localhost:5432/test';

var tables = require('./fixtures/schema').tables;
var functions = require('./fixtures/schema').functions;

var sqlVersion = 'SELECT SUM(10);';

var sqlTableSchema = 'SELECT table_name FROM information_schema.tables WHERE table_name = \
  ANY(ARRAY[\'map\', \'grid_key\', \'keymap\', \'metadata\', \'grid_utfgrid\', \'images\', \
  \'geocoder_data\'])';

var sqlFunctions = 'SELECT p.proname as function_name FROM pg_proc AS p WHERE p.proname = \
  ANY(ARRAY[\'cdb_xyz_resolution\', \'cdb_xyz_extent\', \'z\', \'labelgrid\', \'linelabel\', \
  \'topoint\', \'clean_int\', \'clean_numeric\', \'zres\', \'merc_buffer\', \'merc_length\', \'merc_dwithin\']);';

var sqlCreate = path.join(__dirname, './fixtures/createSchema.sql');
var sqlDrop = path.join(__dirname, './fixtures/dropSchema.sql');

describe('PGTiles', function() {

  describe('Query', function() {
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
  });

  describe('Create', function() {
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

  describe('Rollback', function() {
    beforeEach(function(done) {
      readSql(sqlCreate, function(err, sql) {
        if (err) {
          return done(err);
        }

        var tiles = PGTiles(connString);

        tiles.query(sql, function(error, res) {
          done(error);
        });
      });
    });

    it('should succesfully rollback the table schema', function(done) {
      var tiles = PGTiles(connString);

      tiles.rollback(function(err, res) {
        if (err) {
          return done(err);
        }

        expect(res.command).to.equal('DROP');

        tiles.query(sqlTableSchema, function(error, result) {
          var rows = result.rows;
          expect(rows.length).to.equal(0);
          done(error);
        });
      });
    });

    it('should succesfully rollback the functions', function(done) {
      var tiles = PGTiles(connString);

      tiles.rollback(function(err, res) {
        if (err) {
          return done(err);
        }

        expect(res.command).to.equal('DROP');

        tiles.query(sqlFunctions, function(error, result) {
          var rows = result.rows;
          expect(rows.length).to.equal(0);
          done(error);
        });
      });
    });
  });
});
