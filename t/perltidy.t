#!/usr/bin/env perl

use Test::PerlTidy 'run_tests';

run_tests(
    path     => 'lib',
    perltidy => '.perltidyrc',
);
