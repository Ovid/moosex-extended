#!/usr/bin/env perl

use lib 'lib';
use Test::Most;

use MooseX::SafeDefaults        ();
use MooseX::SafeDefaults::Types ();
use MooseX::SafeDefaults::Role  ();

pass "We were able to lood our primary modules";

diag "Testing MooseX::SafeDefaults $MooseX::SafeDefaults::VERSION, Perl $], $^X";

done_testing;
