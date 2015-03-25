node-pgtiles
============
PostgreSQL schema for vector tiles. Modeled from Mapbox [mbtiles](https://github.com/mapbox/node-mbtiles) and CartoDB [postgresql extensions](https://github.com/CartoDB/cartodb-postgresql/tree/9114d4e463c8664c1fb31e3bc538ce96c0dd0771)

## Dependencies

- [PostgreSQL](http://www.postgresql.org/)
- [Node.js](https://nodejs.org/)
- [NPM](https://npmjs.com)

## Install

`$ npm install pgtiles`

## Use

```js
var pgtiles = require('pgtiles');
var connectionString = 'postgres://username:password@host:dbname/5432';

var tileSchema = pgtiles(connectionString);

// Add the table schema and functions to the designated PostgreSQL database
tileSchema.create(function(err, result) {
  if (err) {
   // handle error
  }

  console.log(result);
  // Result show the tables and functions created
});

// Remove the tables and functions to rollback the database
tileSchema.rollback(function(err, result) {
  if (err) {
    // handle error
  }

  console.log(result);
  // Result show the tables and functions dropped
});
```


Andy B
