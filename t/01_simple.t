#!/usr/bin/perl -T

use strict;
use warnings;

use Data::Validate::OpenAPI;
use JSON;
use Test::Deep;
use Test::More;
use Test::Taint;

my @valid_ids = ( '0', '123', '0123' );

plan tests => 1 + 2 * @valid_ids;

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

for (@valid_ids) {
    my $input = { id => $_ };

    taint( values %$input );

    my $parameters = $api->validate( '/', 'get', $input );

    cmp_deeply( $parameters, { id => int $_ } );
    untainted_ok_deeply( $parameters );
}
