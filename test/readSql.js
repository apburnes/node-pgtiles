'use strict';

var path = require('path');
var chai = require('chai');
var expect = chai.expect;
var readSql = require('../lib/readSql');

var textFile1 = path.join(__dirname, './fixtures/text1.txt');
var textFile2 = path.join(__dirname, './fixtures/text2.txt');
var notTextFile = path.join(__dirname, './fixtures/notafile.txt');
var wrongDataType = {};

describe('readSql', function() {
  it('should successfully read a file given a path', function(done) {
    readSql(textFile1, function(err, text) {
      expect(text).to.be.a('string');
      done(err);
    });
  });

  it('should successfully read an array of file paths', function(done) {
    var files = [textFile1, textFile2];

    readSql(files, function(err, text) {
      expect(text).to.be.a('string');
      done(err);
    });
  });

  it('should reject if the file does not exist', function(done) {
    readSql(notTextFile, function(err) {
      expect(err).to.be.instanceof(Error);
      done();
    });
  });

  it('should reject if a file in the array of files does not exist', function(done) {
    var files = [notTextFile, textFile1];

    readSql(files, function(err) {
      expect(err).to.be.instanceof(Error);
      done();
    });
  });

  it('should reject if the input read param is not a file path string or array of paths', function(done) {
    readSql(wrongDataType, function(err) {
      expect(err).to.be.instanceof(Error);
      done();
    });
  });
});
