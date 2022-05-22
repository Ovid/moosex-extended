#!/usr/bin/env perl

use lib 'lib';
use Test::Most;

#$MooseX::Extreme::Debug = 1;

package My::Point::Moose {
    use Moose;
    use MooseX::Extreme::Types qw(Num);

    has [ 'x', 'y' ] => ( is => 'ro', isa => Num );
    __PACKAGE__->meta->make_immutable;
}

package My::Point::Mutable::Moose {
    use Moose;
    extends 'My::Point::Moose';

    has '+x' => ( is => 'ro', writer => 'set_x', clearer => 'clear_x', default => 0 );
    has '+y' => ( is => 'ro', writer => 'set_y', clearer => 'clear_y', default => 0 );
    __PACKAGE__->meta->make_immutable;
}

package My::Point {
    use MooseX::Extreme;
    use MooseX::Extreme::Types qw(Num);

    param [ 'x', 'y' ] => ( isa => Num );
}

package My::Point::Mutable {
    use MooseX::Extreme;
    extends 'My::Point';

    param [ '+x', '+y' ] => ( writer => 1, clearer => 1, default => 0 );
}

foreach my $class (qw/My::Point::Moose My::Point/) {
    subtest "moose and moosex should behave the same" => sub {
        subtest 'Read-only' => sub {
            my $point = $class->new( x => 7, y => 7.3 );
            is $point->x, 7,   'x should be correct';
            is $point->y, 7.3, 'y should be correct';

            throws_ok { $point->x(3) }
            'Moose::Exception::CannotAssignValueToReadOnlyAccessor',
              'My::Point is immutable';
        };
    };
}

foreach my $class (qw/My::Point::Mutable::Moose My::Point::Mutable/) {
    subtest "moose and moosex should behave the same" => sub {
        subtest 'Read-write' => sub {
            my $point = $class->new( x => 7, y => 7.3 );
            is $point->x, 7,   'x should be correct';
            is $point->y, 7.3, 'y should be correct';

            throws_ok { $point->x(3) }
            'Moose::Exception::CannotAssignValueToReadOnlyAccessor',
              'My::Point is immutable';

            $point->set_x(2);
            is $point->x, 2, '... and our subclass can allow us to set the attributes';
        };
    };
}

done_testing;
