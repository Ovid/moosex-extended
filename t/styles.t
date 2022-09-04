#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests;

subtest 'default style' => sub {

    package Style::Default {
        use MooseX::Extended;

        param name => ( reader => 1, writer => 1 );
        field created => ( reader => 1, writer => 1, builder => 1 );

        sub _build_created ($self) {'now'}
    }

    my $style = Style::Default->new( name => 'Ovid' );
    is $style->get_name, 'Ovid', '"get_" should be the default for reader => 1';
    ok $style->set_name('Bob'), '"set_" should be the default for writer => 1';
    is $style->get_name, 'Bob', '... and it should work as expected';

    is $style->get_created, 'now', 'fields readers should also work as expected';
    ok $style->set_created('later'), '... as should their writers';
    is $style->get_created, 'later', '... and we should get the value we expected';
};

subtest 'get_set' => sub {

    package Style::GetSet {
        use MooseX::Extended style => 'get_set';

        param name => ( reader => 1, writer => 1 );
        field created => ( reader => 1, writer => 1, builder => 1 );

        sub _build_created ($self) {'now'}
    }

    my $style = Style::GetSet->new( name => 'Ovid' );
    is $style->get_name, 'Ovid', '"get_" should be the default for reader => 1';
    ok $style->set_name('Bob'), '"set_" should be the default for writer => 1';
    is $style->get_name, 'Bob', '... and it should work as expected';

    is $style->get_created, 'now', 'fields readers should also work as expected';
    ok $style->set_created('later'), '... as should their writers';
    is $style->get_created, 'later', '... and we should get the value we expected';
};

subtest 'set' => sub {

    package Style::Set {
        use MooseX::Extended style => 'set';

        param name => ( reader => 1, writer => 1 );
        field created => ( reader => 1, writer => 1, builder => 1 );

        sub _build_created ($self) {'now'}
    }

    my $style = Style::Set->new( name => 'Ovid' );
    is $style->name, 'Ovid', '"get_" should be the default for reader => 1';
    ok $style->set_name('Bob'), '"set_" should be the default for writer => 1';
    is $style->name, 'Bob', '... and it should work as expected';

    is $style->created, 'now', 'fields readers should also work as expected';
    ok $style->set_created('later'), '... as should their writers';
    is $style->created, 'later', '... and we should get the value we expected';
};

subtest 'custom' => sub {

    package Style::Custom {
        use MooseX::Extended style => {
            predicate => sub {"is_$_[0]"},
            clearer   => sub {"remove_$_[0]"},
            builder   => sub {"_do_$_[0]"},
            writer    => sub {"set_the_$_[0]"},
            reader    => sub {"get_the_$_[0]"},
        };

        param name        => ( reader      => 1, writer => 1 );
        param initialized => ( initializer => 1 );
        field created => ( reader => 1, writer => 1, builder => 1 );

        sub _initialize_initialized ( $self, $value, $set, $attr ) {
            $set->( $value * 2 );
        }
        sub _do_created ($self) {'now'}
    }

    my $style = Style::Custom->new( name => 'Ovid', initialized => 3 );
    is $style->get_the_name, 'Ovid', '"get_" should be the default for reader => 1';
    ok $style->set_the_name('Bob'), '"set_" should be the default for writer => 1';
    is $style->get_the_name, 'Bob', '... and it should work as expected';

    is $style->initialized, 6, 'Our initializers fire as expected';

    is $style->get_the_created, 'now', 'fields readers should also work as expected';
    ok $style->set_the_created('later'), '... as should their writers';
    is $style->get_the_created, 'later', '... and we should get the value we expected';
};

subtest 'custom with defaults' => sub {

    package Style::CustomWithDefaults {
        use MooseX::Extended style => {
            predicate => sub {"has_$_[0]"},
            reader    => sub { $_[0] },
        };

        param name => ( reader => 1, writer => 1 );
        field created => ( reader => 1, writer => 1, predicate => 1 );
    }

    my $style = Style::CustomWithDefaults->new( name => 'Ovid' );
    is $style->name, 'Ovid', '"get_" should be the default for reader => 1';
    ok $style->set_name('Bob'), '"set_" should be the default for writer => 1';
    is $style->name, 'Bob', '... and it should work as expected';

    ok !$style->has_created,       'We can override just the styles we want';
    ok !defined $style->created,   'fields readers should also work as expected';
    ok $style->set_created('now'), '... as should their writers';
    is $style->created, 'now', '... and we should get the value we expected';
    ok $style->has_created, '... and predicate methods work as expected';
};
done_testing;
