'use strict';

var pg = require('pg.js');
var create = require('./lib/create');
var rollback = require('./lib/rollback');

function pgTiles(connString) {
  if (!(this instanceof pgTiles)) {
    return new pgTiles(connString);
  }

  this.connectionString = connString;
}

pgTiles.prototype.query = function(sql, callback) {
  var connString = this.connectionString;

  pg.connect(connString, function(err, client, done) {
    function handelError(err) {
      done(client);
      return callback(err);
    }

    if (err) {
      return handelError(err);
    }

    client.query(sql, function(error, result) {
      if (error) {
        return handelError(error);
      }

      return callback(null, result);
    });
  });
}

pgTiles.prototype.create = function(callback) {
  var self = this;
  var query = pgTiles.prototype.query;

  create(function(err, sql) {
    if (err) {
      return callback(err);
    }

    query.call(self, sql, function(error, result) {
      if (err) {
        return callback(error);
      }

      return callback(null, result);
    });
  });
}

pgTiles.prototype.rollback = function(callback) {
  var self = this;
  var query = pgTiles.prototype.query;

  rollback(function(err, sql) {
    if (err) {
      return callback(err);
    }

    query.call(self, sql, function(error, result) {
      if (error) {
        return callback(error);
      }

      return callback(null , result);
    });
  });
}

module.exports = pgTiles;


