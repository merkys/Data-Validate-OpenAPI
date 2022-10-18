package Data::Validate::OpenAPI;

use strict;
use warnings;

use base OpenAPI::Render::;

use Data::Validate qw( is_integer );
use Data::Validate::Email qw( is_email );

sub validate
{
    my( $self, $path, $method, $cgi ) = @_;

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
    my $par_hash = $cgi->Vars;

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

        if( !defined $format ) {
            # nothing to do here
        } elsif( $format eq 'email' ) {
            $value = is_email $value;
        } elsif( $format eq 'integer' ) {
            $value = is_integer $value;
        }

        if( $schema && $schema->{pattern} ) {
            if( $value =~ /^($schema->{pattern})$/ ) {
                $value = $1;
            } else {
                undef $value;
            }
        }

        if( defined $value && $value eq '' &&
            ( !exists $description->{allowEmptyValue} ||
              $description->{allowEmptyValue} eq 'false' ) ) {
            undef $value;
        }

        next unless defined $value;
        $par->{$name} = $value;
    }
}

1;
