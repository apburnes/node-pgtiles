'use strict';

var fs = require('fs');
var _ = require('lodash');

function readFiles(fileArray, callback) {
  var files = [];

  var done = _.after(fileArray.length, function() {
    var sql = files.join('\n');
    return callback(null, sql);
  });

  _.map(fileArray, function(file) {
    fs.readFile(file, 'utf-8', function(err, data) {
      if (err) {
        return callback(err);
      }

      files.push(data);
      done();
    });
  });
}

function readSql(sqlFile, callback) {
  if (_.isString(sqlFile)) {
    fs.readFile(sqlFile, 'utf-8', function(err, sql) {
      if (err) {
        return callback(err);
      }

      return callback(null, sql);
    });
  }
  else if (_.isArray(sqlFile)) {
    return readFiles(sqlFile, callback);
  }
  else {
    return callback(new Error('Input file paramater is not a file path string or array of strings'));
  }
}

module.exports = readSql;
