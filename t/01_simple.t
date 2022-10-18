#!/usr/bin/perl

use strict;
use warnings;

use Data::Validate::OpenAPI;
use JSON;
use Test::Deep;
use Test::More tests => 1;

my $api = Data::Validate::OpenAPI->new( decode_json '
{
  "paths": {
    "/": {
      "get": {
        "parameters": [
          {
            "name": "id",
            "in": "query",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ]
      }
    }
  }
}
' );

my $input = { id => 123 };

my $parameters = $api->validate( '/', 'get', $input );
cmp_deeply( $parameters, $input );
