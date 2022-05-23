# NAME

MooseX::Extreme - Moose on Steroids

# VERSION

version 0.01

# SYNOPSIS

```perl
package My::Names {
    use MooseX::Extreme;
    use MooseX::Extreme::Types
      qw(compile Num NonEmptyStr Str PositiveInt ArrayRef);
    use List::Util 'sum';

    # the distinction between `param` and `field` makes it easier to
    # see which are available to `new`
    param _name   => ( isa => NonEmptyStr, init_arg => 'name' );
    param title   => ( isa => Str,         required => 0 );

    # forbidden in the constructor
    field created => ( isa => PositiveInt, default  => sub { time } );

    sub name ($self) {
        my $title = $self->title;
        my $name  = $self->_name;
        return $title ? "$title $name" : $name;
    }

    sub add ( $self, $args ) {
        state $check = compile( ArrayRef [Num, 1] ); # at least one number
        ($args) = $check->($args);
        return sum( $args->@* );
    }

    sub warnit ($self) {
        carp("this is a warning");
    }
}
```

# DESCRIPTION

This module is **EXPERIMENTAL**! All features subject to change.

This class attempts to create a safer version of Moose that defaults to
read-only attributes and is easier to read and write.

It tries to bring some of the lessons learned from [the Corinna project](https://github.com/Ovid/Cor),
while acknowledging that you can't always get what you want (such as
true encapsulation and true methods).

This:

```perl
package My::Class {
    use MooseX::Extreme;

    ... your code here
}
```

Is sort of the equivalent to:

```perl
package My::Class {
    use v5.20.0;
    use Moose;
    use MooseX::StrictConstructor;
    use feature qw( signatures postderef );
    no warnings qw( experimental::signatures experimental::postderef );
    use namespace::autoclean;
    use Carp;
    use mro 'c3';

    ... your code here

    __PACKAGE__->meta->make_immutable;
}
1;
```

It also exports two functions which are similar to Moose `has`: `param` and
`field`.

A `param` is a required parameter (defaults may be used). A `field` is not
allowed to be passed to the constructor.

Note that the `has` function is still available, even if it's not needed.

# Immutability

## Making Your Class Immutable

Typically Moose classes should end with this:

```
__PACKAGE__->meta->make_immutable;
```

That prevents further changes to the class and provides some optimizations to
make the code run much faster. However, it's somewhat annoying to type. We do
this for you, via `B::Hooks::AtRuntime`. You no longer need to do this yourself.

## Immutable Objects

By default, attributes defined via `param` and `field` are read-only.
However, if they contain a reference, you can fetch the reference, mutate it,
and now everyone with a copy of that reference has mutated state.
`MooseX::Extreme` offers **EXPERIMENTAL** support for cloning, but differently
from how we see it typically done. You can just pass the `clone => 1`
argument to your attribute and it will be clone with [Storable](https://metacpan.org/pod/Storable)'s `dclone`
function every time you read or write that attribute, it will be cloned if
it's a reference, ensuring that your object is effectively immutable.

If you prefer, you can also pass a code reference or the name of a method you
will use to clone the object. Each will receive three arguments:
`$self, $attribute_name, $value_to_clone`. Here's a full example, taken
from our test suite.

```perl
package My::Class {
    use MooseX::Extreme;
    use MooseX::Extreme::Types qw(NonEmptyStr HashRef InstanceOf);

    param name => ( isa => NonEmptyStr );

    param payload => (
        isa    => HashRef,
        clone  => 1,  # uses Storable::dclone
        writer => 1,
    );

    param start_date => (
        isa   => InstanceOf ['DateTime'],
        clone => sub ( $self, $name, $value ) {
            return $value->clone;
        },
    );

    param end_date => (
        isa    => InstanceOf ['DateTime'],
        clone  => '_clone_end_date',
    );

    sub _clone_end_date ( $self, $name, $value ) {
        return $value->clone;
    }

    sub BUILD ( $self, @ ) {
        if ( $self->end_date < $self->start_date ) {
            croak("End date must not be before start date");
        }
    }
}
```

**Warning**: setting the value via the constructor for the first time doesn't
clone the data. All other gets and sets will clone it. We need to figure out a
clean, performant solution for this.

# OBJECT CONSTRUCTION

The normal `new`, `BUILD`, and `BUILDARGS` functions work as expected.
However, we apply [MooseX::StrictConstructor](https://metacpan.org/pod/MooseX%3A%3AStrictConstructor) to avoid this problem:

```perl
my $soldier = Soldier->new(
    name   => $name,
    rank   => $rank,
    seriel => $serial, # should be serial
);
```

By default, misspelled arguments to the [Moose](https://metacpan.org/pod/Moose) constructor are silently discarded,
leading to hard-to-diagnose bugs. With [MooseX::Extreme](https://metacpan.org/pod/MooseX%3A%3AExtreme), they're a fatal error.

If you need to pass arbitrary "sideband" data, explicitly declare it as such:

```perl
param sideband => ( isa => HashRef, default => sub { {} } );
```

Naturally, because we bundle `MooseX::Extreme::Types`, you can do much
finer-grained data validation on that, if needed.

# FUNCTIONS

The following two functions are exported into your namespace.

## `param`

```perl
param name => ( isa => NonEmptyStr );
```

A similar function to Moose's `has`. A `param` is required. You may pass it
to the constructor, or use a `default` or `builder` to supply this value.

The above `param` definition is equivalent to:

```perl
has name => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);
```

If you want a parameter that has no `default` or `builder` and can
_optionally_ be passed to the constructor, just use `required => 0`.

```perl
param title => ( isa => Str, required => 0 );
```

Note that `param`, like `field`, defaults to read-only, `is => 'ro'`.
You can override this:

```perl
param name => ( is => 'rw', isa => NonEmptyStr );
```

Otherwise, it behaves like `has`. You can pass in any arguments that `has`
accepts.

```perl
# we'll make it private, but allow it to be passed to the constructor
# as `name`
param _name   => ( isa => NonEmptyStr, init_arg => 'name' );
```

## `field`

```perl
field created => ( isa => PositiveInt, default => sub { time } );
```

A similar function to Moose's `has`. A `field` is never allowed to be passed
to the constructor, but you can still use `default` or `builder`, as normal.

The above `field` definition is equivalent to:

```perl
has created => (
    is       => 'ro',
    isa      => PositiveInt,
    init_arg => undef,        # not allowed in the constructor
    default  => sub { time },
    lazy     => 1,
);
```

Note that `field`, like `param`, defaults to read-only, `is => 'ro'`.
You can override this:

```perl
field some_data => ( is => 'rw', isa => NonEmptyStr );
```

Otherwise, it behaves like `has`. You can pass in any arguments that `has`
accepts.

**WARNING**: if you pass `field` an `init_arg` with a defined value, The code
will `croak`. A `field` is just for instance data the class uses. It's not
to be passed to the constructor. If you want that, just use `param`.

Later, we'll add proper exceptions.

### Lazy Fields

Every `field` is lazy by default. This is because there's no guarantee the code will call
them, but this makes it very easy for a `field` to rely on a `param` value being present.

Every `param` is not lazy by default, but you can add `lazy => 1` if you need to.

# ATTRIBUTE SHORTCUTS

When using `field` or `param`, we have some attribute shortcuts:

```perl
param name => (
    isa       => NonEmptyStr,
    writer    => 1,   # set_name
    reader    => 1,   # get_name
    predicate => 1,   # has_name
    clearer   => 1,   # clear_name
    builder   => 1,   # _build_name
);

sub _build_name ($self) {
    ...
}
```

These can also be used when you pass an array reference to the function:

```perl
package Point {
    use MooseX::Extreme;
    use MooseX::Extreme::Types qw(Int);

    param [ 'x', 'y' ] => (
        isa     => Int,
        clearer => 1,     # clear_x and clear_y available
        default => 0,
    ) :;
}
```

Note that these are _shortcuts_ and they make attributes easier to write and more consistent.
However, you can still use full names:

```perl
field authz_delegate => (
    builder => '_build_my_darned_authz_delegate',
);
```

## `writer`

If an attribute has `writer` is set to `1` (the number one), a method
named `set_$attribute_name` is created.

This:

```perl
param title => (
    isa       => Undef | NonEmptyStr,
    default   => undef,
    writer => 1,
);
```

Is the same as this:

```perl
has title => (
    is      => 'rw',                  # we change this from 'ro'
    isa     => Undef | NonEmptyStr,
    default => undef,
    writer  => 'set_title',
);
```

## `reader`

By default, the reader (accessor) for the attribute is the same as the name.
You can always change this:

```perl
has payload => ( is => 'ro', reader => 'the_payload' );
```

However, if you want to change the reader name

If an attribute has `reader` is set to `1` (the number one), a method
named `get_$attribute_name` is created.

This:

```perl
param title => (
    isa       => Undef | NonEmptyStr,
    default   => undef,
    reader => 1,
);
```

Is the same as this:

```perl
has title => (
    is      => 'rw',                  # we change this from 'ro'
    isa     => Undef | NonEmptyStr,
    default => undef,
    reader  => 'get_title',
);
```

## `predicate`

If an attribute has `predicate` is set to `1` (the number one), a method
named `has_$attribute_name` is created.

This:

```perl
param title => (
    isa       => Undef | NonEmptyStr,
    default   => undef,
    predicate => 1,
);
```

Is the same as this:

```perl
has title => (
    is        => 'ro',
    isa       => Undef | NonEmptyStr,
    default   => undef,
    predicate => 'has_title',
);
```

## `clearer`

If an attribute has `clearer` is set to `1` (the number one), a method
named `clear_$attribute_name` is created.

This:

```perl
param title => (
    isa     => Undef | NonEmptyStr,
    default => undef,
    clearer => 1,
);
```

Is the same as this:

```perl
has title => (
    is      => 'ro',
    isa     => Undef | NonEmptyStr,
    default => undef,
    clearer => 'clear_title',
);
```

## `builder`

If an attribute has `builder` is set to `1` (the number one), a method
named `_build_$attribute_name`.

This:

```perl
param title => (
    isa     =>  NonEmptyStr,
    builder => 1,
);
```

Is the same as this:

```perl
has title => (
    is      => 'ro',
    isa     => NonEmptyStr,
    builder => '_build_title',
);
```

Obviously, a "private" attribute, such as `_auth_token` would get a build named
`_build__auth_token` (note the two underscores between "build" and "auth\_token").

# RELATED MODULES

- [MooseX::Extreme::Types](https://metacpan.org/pod/MooseX%3A%3AExtreme%3A%3ATypes) is included in the distribution.

    This provides core types for you.

- [MooseX::Extreme::Role](https://metacpan.org/pod/MooseX%3A%3AExtreme%3A%3ARole) is included in the distribution.

    `MooseX::Extreme`, but for roles.

# TODO

Some of this may just be wishful thinking. Some of this would be interesting if
others would like to collaborate.

## Tests

Tests! Many more tests! Volunteers welcome :)

## Configurable Types

We provide `MooseX::Extreme::Types` for convenience. It would be even more
convenient if we offered an easier for people to build something like
`MooseX::Extreme::Types::Mine` so they can customize it.

## Configurability

Not everyone wants everything. In particular, using `MooseX::Extreme` with
[DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass) will be fatal because the latter allows unknown arguments to
constructors.  Or someone might want their "own" extreme Moose, requiring
`v5.36.0` or not using the C3 mro. What's the best way to allow this?

## `BEGIN::Lift`

This idea maybe belongs in `MooseX::Extremely::Extreme`, but ...

Quite often you see things like this:

```
BEGIN { extends 'Some::Parent' }
```

Or this:

```perl
sub serial_number; # required by a role, must be compile-time
has serial_number => ( ... );
```

In fact, there are a variety of Moose functions which would work better if
they ran at compile-time instead of runtime, making them look a touch more
like native functions. My various attempts at solving this have failed, but I
confess I didn't try too hard.

# NOTES

There are a few things you might be interested to know about this module when
evaluating it.

Most of this is written with bog-standard [Moose](https://metacpan.org/pod/Moose), so there's nothing
terribly weird inside. However, there are a couple of modules which stand out.

We do not need `__PACKAGE__->meta->make_immutable` because we use
[B::Hooks::AtRuntime](https://metacpan.org/pod/B%3A%3AHooks%3A%3AAtRuntime)'s `after_runtime` function to set it.

We do not need a true value at the end of a module because we use [true](https://metacpan.org/pod/true).

# SEE ALSO

- [MooseX::Modern](https://metacpan.org/pod/MooseX::Modern)
- [Corinna](https://github.com/Ovid/Cor)

# AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
