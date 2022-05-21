#!/usr/bin/env perl

use lib 'lib';
use Test::Most;
use Scalar::Util 'refaddr';

#$MooseX::Extreme::Debug = 1;
my $CLONE_CALLED = 0;

package My::Class {
    use v5.22.0;
    use MooseX::Extreme;
    use MooseX::Extreme::Types qw(NonEmptyStr HashRef);

    param name => ( isa => NonEmptyStr );
    param payload => (
        isa     => HashRef,
        clone   => 1,
        trigger => sub { $CLONE_CALLED++ },
        writer  => 1,
    );
}

my $payload = {
    this => [ 1, 2, 4 ],
    that => {
        is      => 'going',
        'to be' => 'cloned',
    },
};
my $object = My::Class->new(
    name    => 'Ovid',
    payload => $payload,
);

is $object->name, 'Ovid', 'Our name should be correct';
ok my $recovered = $object->payload, 'We should be able to fetch our object payload';
eq_or_diff $recovered, $payload, '... and it should have the correct data';
cmp_ok refaddr($recovered), '!=', refaddr($payload), '... but it should not be an alias to the original data structure';
$payload->{that}{foo} = 42;
TODO: {
    local $TODO = 'Bug: the first time we set the value via new(), it does not get cloned properly';
    ok !exists $object->payload->{that}{foo}, '... and mutating the state of the original data structure should not change our data structure';
}
my $recovered2 = $object->payload;

cmp_ok refaddr($recovered2), '!=', refaddr($payload),   '... but it should not be an alias to the original data structure';
cmp_ok refaddr($recovered2), '!=', refaddr($recovered), '... but it should not be an alias to the original data structure';

my $new_payload = {};
$object->set_payload($new_payload);
eq_or_diff $object->payload, {}, 'We should be able to set our new value';
$new_payload->{foo} = 1;
eq_or_diff $object->payload, {}, '... but changing the original data structure does not change our attribute value';

done_testing;
