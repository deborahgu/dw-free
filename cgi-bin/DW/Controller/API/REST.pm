#!/usr/bin/perl
#
# DW::Controller::API::REST
#
# This module extends the API for REST-specific functionality.
#
# Authors:
#      Allen Petersen <allen@suberic.net>, Deborah Kaplan <deborah@dreamwidth.org>
#
# Copyright (c) 2017 by Dreamwidth Studios, LLC.
#
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. For a copy of the license, please reference
# 'perldoc perlartistic' or 'perldoc perlgpl'.
#

# FIXME: this file needs pod. APIs need to be self-documenting.
# FIXME: hitting endpoints without parameters should generate documentation from the pod.

package DW::Controller::API::REST;

use strict;
use warnings;
use DW::Request;
use DW::Routing;
use DW::Controller;
use DW::Controller::API;
use JSON;
use Pod::Html;

use Carp qw/ croak /;

# Usage: DW::Controller::API::REST->register_rest_endpoints( $endpoint , $ver );
#
# Registers default GET, POST, PUT, and DELETE handlers for
# /api/v$ver/$endpoint as well as /api/v$ver/$endpoint/($id)
sub register_rest_controller {
    my ( $self, $endpoint, $ver ) = @_;

    # FIXME: remove debugging log messages before prod
    warn("register rest controller for $endpoint using $self ");
    DW::Routing->register_api_rest_endpoints(
        [ $endpoint . '$', "_list_dispatcher", $self, $ver ],
        [ $endpoint . '/([^/]*)$', "_item_dispatcher", $self, $ver ],
        );
}

# Private for a single item
sub _item_dispatcher {
    my ( $self, @args ) = @_;

    # FIXME: remove debugging log messages before prod
    warn(" running REST _item_dispatcher; self = " . $self );
    my ( $ok, $rv ) = controller( anonymous => 1 );
    return $rv unless $ok;

    # rv->{r}: the DW:Request object. The request knows which method was used.
    # Call the appropriate REST method from the class.
    my $r = $rv->{r};
    if ( $r->method eq 'GET' ) {
        return $self->rest_get_item( @args );
    } elsif ( $r->method eq 'POST' ) {
        return $self->rest_post_item( @args );
    } elsif ( $r->method eq 'PUT' ) {
        return $self->rest_put_item( @args );
    } elsif ( $r->method eq 'DELETE' ) {
        return $self->rest_delete_item( @args );
    } else {
        return $self->_rest_unimplemented();
    }
}

# Private for a list of items
sub _list_dispatcher {
    my ( $self, @args ) = @_;

    # FIXME: remove debugging log messages before prod
    warn(" running REST _list_dispatcher; self = " . $self );
    my ( $ok, $rv ) = controller( anonymous => 1 );
    return $rv unless $ok;

    # rv->{r}: the DW:Request object. The request knows which method was used.
    # Call the appropriate REST method from the class.
    my $r = $rv->{r};
    if ( $r->method eq 'GET' ) {
        return $self->rest_get_list( @args );
    } elsif ( $r->method eq 'POST' ) {
        return $self->rest_post_list( @args );
    } elsif ( $r->method eq 'PUT' ) {
        return $self->rest_put_list( @args );
    } elsif ( $r->method eq 'DELETE' ) {
        return $self->rest_delete_list( @args );
    } else {
        return $self->_rest_unimplemented();
    }
}

# Parent GET method for list. Should never be called.
sub rest_get_list {
    my $self = $_[0];
    warn( "default get list; self=" . $self );
    return _rest_unimplemented( "GET" );
}

# GET is the only implemented method so far
sub rest_post_list {
    return _rest_unimplemented( "POST" );
}

# GET is the only implemented method so far
sub rest_put_list {
    return _rest_unimplemented( "PUT" );
}

# GET is the only implemented method so far
sub rest_delete_list {
    return _rest_unimplemented( "DELETE" );
}

# Parent GET method for item. Should never be called.
sub rest_get_item {
    my $self = $_[0];
    warn( "default get item; self=" . $self );
    return _rest_unimplemented( "GET" );
}

# GET is the only implemented method so far
sub rest_post_item {
    return _rest_unimplemented( "POST" );
}

# GET is the only implemented method so far
sub rest_put_item {
    return _rest_unimplemented( "PUT" );
}

# GET is the only implemented method so far
sub rest_delete_item {
    return _rest_unimplemented( "DELETE" );
}

# Private function for a safe return on unimplemented REST methods
sub _rest_unimplemented {
    my $error = $_[0] . " Not Implemented";
    my $r = DW::Request->get;

    return rest_error( $r->HTTP_METHOD_NOT_ALLOWED, $error);
}

# Usage: return rest_error( $r->STATUS_CODE_CONSTANT,
#                          'format/message', [arg, arg, arg...] )
# Returns a standard format JSON error message.
# First argument is the status code
# Second argument is a string (format string allowed).
sub rest_error {
    my $status_code = shift;
    # Default error string if one isn't provided
    my $message = scalar @_ >= 2 ?
        sprintf( shift, @_ ) : 'Unknown error.';

    my $response = {
        success => 0,
        error   => $message,
    };

    # Send the JSON response and set the status code
    my $r = DW::Request->get;
    $r->print( to_json( $response ) );
    $r->status( $status_code );
    return;
}

# Usage: return rest_ok( SCALAR )
# SCALAR can be a hashref, arrayref, or value.
# Returns a standard format JSON success message of SCALAR
# with a 200 success status code.
sub rest_ok {
    croak 'rest_ok takes one argument only'
        unless scalar @_ == 2;

    my ( $self, $response ) = @_;
    my $r = DW::Request->get;

    my $json_response = {
        success => 1,
        result  => $response,
    };

    $r->print( to_json( $json_response, { convert_blessed => 1 } ) );
    $r->status( 200 );
    return;
}


1;
