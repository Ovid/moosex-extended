#!/usr/bin/env perl

use Test::Most;
use Test::PerlTidy 'run_tests';

TODO: {
    local $TODO = 'dzil test does not copy perltidyrc into the ./build directory https://github.com/Ovid/moosex-extreme/issues/3';
    run_tests(
        path     => 'lib',
        perltidy => 't/perltidyrc',
    );
}
