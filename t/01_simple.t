#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use lib '../OpenAPI-Render/lib';

use Data::Validate::OpenAPI;
use JSON;
use Test::Deep;
use Test::More tests => 3;
use Test::Taint;

taint_checking_ok();

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
              "format": "integer"
            }
          }
        ]
      }
    }
  }
}
' );

my $input = { id => 123 };

taint( values %$input );

my $parameters = $api->validate( '/', 'get', $input );

cmp_deeply( $parameters, $input );
untainted_ok_deeply( $parameters );
