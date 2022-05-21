#!/usr/bin/env perl

use lib 'lib';
use Test::Most;

use MooseX::Extreme        ();
use MooseX::Extreme::Types ();
use MooseX::Extreme::Role  ();

pass "We were able to lood our primary modules";

diag "Testing MooseX::Extreme $MooseX::Extreme::VERSION, Perl $], $^X";

done_testing;
