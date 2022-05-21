#!/usr/bin/env perl

use strict;
use warnings;
use Test::PerlTidy 'run_tests';

run_tests(
    path     => 'lib',
    perltidy => '.perltidyrc',
);
