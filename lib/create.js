'use strict';

var path = require('path');
var readSql = require('./readSql');

var createFunctions = path.join(__dirname, '../sql/createFunctions.sql');
var createSchema = path.join(__dirname, '../sql/createSchema.sql');

var files = [createSchema, createFunctions];

function create(callback) {
  readSql(files, function(err, sql) {
    if (err) {
      return callback(err);
    }

    return callback(null, sql);
  });
}

module.exports = create;
