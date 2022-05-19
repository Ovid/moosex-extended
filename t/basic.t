#!/usr/bin/env perl

use lib 'lib';
use Test::Most;

package My::Names {
    use v5.22.0;
    use MooseX::Extreme;
    use MooseX::Extreme::Types
      qw(compile Num NonEmptyStr Str PositiveInt ArrayRef);
    use List::Util 'sum';

    param _name => ( isa => NonEmptyStr, init_arg => 'name' );
    param title => ( isa => Str,         required => 0 );
    field created => ( isa => PositiveInt, default => sub { time } );

    sub name ($self) {
        my $title = $self->title;
        my $name  = $self->_name;
        return $title ? "$title $name" : $name;
    }

    sub add ( $self, $args ) {
        state $check = compile( ArrayRef [ Num, 1 ] );
        ($args) = $check->($args);
        return sum( $args->@* );
    }

    sub warnit ($self) {
        carp("this is a warning");
    }
}

TODO: {
    local $TODO = 'B::Hooks::EndOfScope is needed for this, I think';
    ok +My::Names->meta->is_immutable,
      'We should be able to define an immutable class';
}

subtest 'no title' => sub {
    my $person = My::Names->new( name => 'Ovid', );
    is $person->name, 'Ovid', 'name should be correct';
    ok !defined $person->title, '... and no title';
    cmp_ok $person->created, '>', 0, '... and a sane default for created';
    ok !$person->can('sum'), 'subroutines have been removed from the namespace';
    is $person->add( [qw/1 3 5 6/] ), 15, 'Our add() method should work';
};

subtest 'has title' => sub {
    my $person = My::Names->new( name => 'Ovid', );
    my $doctor = My::Names->new( name => 'Smith', title => 'Dr.' );
    is $doctor->name, 'Dr. Smith', 'Titles should show up correctly';
    cmp_ok $doctor->created, '>=', $person->created,
      '... and their created date should be correct';
};

subtest 'exceptions' => sub {
    my $person = My::Names->new( name => 'Ovid', );

    throws_ok { $person->title('Mr.') }
    'Moose::Exception::CannotAssignValueToReadOnlyAccessor',
      'Attributes are read-only by default';

    throws_ok { $person->add( [] ) }
    'Error::TypeTiny::Assertion',
      'passing an empty array reference should be fatal';

    throws_ok { My::Names->new( name => 'Ovid', created => 1 ) }
    'Moose::Exception',
      'Attributes not defined as `param` are illegal in the constructor';
};

done_testing;