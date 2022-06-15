#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests
  name   => 'handles-via',
  module => [ 'Sub::HandlesVia', '0.023' ];

{ package Local::Dummy1; use Test::Requires 'MooseX::Extended' };

BEGIN {

    package ExampleMXX;

    use MooseX::Extended types => ['Str'], debug => 1;
    use Sub::HandlesVia;

    has eg1 => (
        is          => 'ro',
        isa         => Str,
        handles_via => 'String',
        handles     => { eg1_append => 'append...' },
    );

    field eg2 => (
        is          => 'ro',
        isa         => Str,
        handles_via => 'String',
        handles     => { eg2_append => 'append...' },
        default     => sub {'eg2'},
    );

    param eg3 => (
        is          => 'ro',
        isa         => Str,
        handles_via => 'String',
        handles     => { eg3_append => 'append...' },
    );
}

my $obj = ExampleMXX->new(
    eg1 => 'eg1',

    #    eg2 => 'eg2',
    eg3 => 'eg3',
)->eg1_append('x')->eg2_append('x')->eg3_append('x');

is( $obj->eg1, 'eg1x', 'has attribute' );
is( $obj->eg2, 'eg2x', 'field attribute' );
is( $obj->eg3, 'eg3x', 'param attribute' );

done_testing;
