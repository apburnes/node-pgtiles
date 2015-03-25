'use strict';

var path = require('path');
var readSql = require('./readSql');

var dropFunctions = path.join(__dirname, '../sql/dropFunctions.sql');
var dropSchema = path.join(__dirname, '../sql/dropSchema.sql');

var files = [dropSchema, dropFunctions];

function rollback(callback) {
  readSql(files, function(err, sql) {
    if (err) {
      return callback(err);
    }

    return callback(null, sql);
  });
}

module.exports = rollback;
