#!/usr/bin/env perl

use lib 'lib';
use Test::Most;

package My::Point {
    use MooseX::Extended types => [qw/Num/];
    param [ 'x', 'y' ] => ( isa => Num );
}

package My::Point::3D {
    use MooseX::Extended types => [qw/Num/];
    extends 'My::Point';
    param 'z' => ( isa => Num );
}

package My::Multi {
    use MooseX::Extended includes => [qw/multi/];

    multi sub point ( $self, $x, $y ) {
        return My::Point->new( x => $x, y => $y );
    }
    multi sub point ( $self, $x, $y, $z ) {
        return My::Point::3D->new( x => $x, y => $y, z => $z );
    }
}

ok my $multi = My::Multi->new, 'We should be allowed to load a class with multimethods';

subtest '2d point' => sub {
    ok my $point = $multi->point( 3, 4 ), 'We can fetch a 2d point';
    ok $point->isa('My::Point'),          '... and it should be the correct class';
    ok !$point->isa('My::Point::3D'),     '... and definitely not the wrong class';
    is $point->x, 3, '... with the correct x';
    is $point->y, 4, '... and the correct y';
    ok !$point->can('z'), '... and it does not have a z attribute';
};
subtest '3d point' => sub {
    ok my $point = $multi->point( 5, 6, 7 ), 'We can fetch a 3d point';
    ok $point->isa('My::Point'),          '... and it should be the correct class';
    ok !$point->isa('My::Point::3D'),     '... and definitely not the wrong class';
    is $point->x, 3, '... with the correct x';
    is $point->y, 4, '... and the correct y';
    ok !$point->can('z'), '... and it does not have a z attribute';
};

done_testing;
