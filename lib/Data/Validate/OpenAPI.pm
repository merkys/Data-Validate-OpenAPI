package Data::Validate::OpenAPI;

use strict;
use warnings;

use base OpenAPI::Render::;

use Data::Validate qw( is_integer );
use Data::Validate::Email qw( is_email );
use Data::Validate::IP qw( is_ipv4 is_ipv6 );
use Data::Validate::URI qw( is_uri );
use Scalar::Util qw( blessed );

sub validate
{
    my( $self, $path, $method, $input ) = @_;

    my $api = $self->{api};
    my @parameters =
        grep { $_->{in} eq 'query' }
        exists $api->{paths}{$path}{parameters}
           ? @{$api->{paths}{$path}{parameters}} : (),
        exists $api->{paths}{$path}{$method}{parameters}
           ? @{$api->{paths}{$path}{$method}{parameters}} : (),
        exists $api->{paths}{$path}{$method}{requestBody}
           ? RequestBody2Parameters( $api->{paths}{$path}{$method}{requestBody} ) : (),
        );

    my $par = {};
    my $par_hash = $input;

    if( blessed $par_hash ) {
        $par_hash = $par_hash->Vars; # object is assumed to be CGI
    }

    for my $description (@parameters) {
        my $name = $description->{name};
        my $schema = $description->{schema} if $description->{schema};
        my $format = $schema->{format} if $schema;
        if( !exists $par_hash->{$name} ) {
            if( $schema && exists $schema->{default} ) {
                $par->{$name} = $schema->{default};
            }
            next;
        }

        my $value = $par_hash->{$name};

        # FIXME: Maybe employ a proper JSON Schema validator? Not sure
        # if it untaints, though.
        if( !defined $format ) {
            # nothing to do here
        } elsif( $format eq 'email' ) {
            $value = is_email $value;
        } elsif( $format eq 'integer' ) {
            $value = is_integer $value;
        } elsif( $format eq 'ipv4' ) {
            $value = is_ipv4 $value;
        } elsif( $format eq 'ipv6' ) {
            $value = is_ipv6 $value;
        } elsif( $format eq 'uri' ) {
            $value = is_uri $value;
        } elsif( $format eq 'uuid' ) {
            # Regex taken from Data::Validate::UUID. Module is not used as
            # it does not untaint the value.
            if( $value =~ /^([0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})$/i ) {
                $value = $1;
            } else {
                undef $value;
            }
        }

        next unless defined $value;

        if( $schema && $schema->{enum} ) {
            ( $value ) = grep { $value eq $_ } @{$schema->{enum}};
            next unless defined $value;
        }

        if( $schema && $schema->{pattern} ) {
            next unless $value =~ /^($schema->{pattern})$/ ) {
            $value = $1;
        }

        if( defined $value && $value eq '' &&
            ( !exists $description->{allowEmptyValue} ||
              $description->{allowEmptyValue} eq 'false' ) ) {
            next; # nothing to do
        }

        next unless defined $value;
        $par->{$name} = $value;
    }

    return $par;
}

1;
