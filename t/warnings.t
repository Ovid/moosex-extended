#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests;

warnings_like {
    package Local::Test1;
    use MooseX::Extended;
    field 'foo';
} qr/field 'foo' is read-only and has no init_arg or default, defined at .+\bwarnings.t line 9/;

warning_is {
    package Local::Test2;
    use MooseX::Extended;
    no warnings 'MooseX::Extended::naked_fields';
    field 'bar';
} undef;

done_testing;
