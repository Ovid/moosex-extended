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
    use v5.22.0;
    use Moose;
    use MooseX::StrictConstructor;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    use namespace::autoclean;
    use Carp;
    use mro 'c3';

    ... your code here
}
```

It also exports two functions which are similar to Moose `has`: `param` and
`field`.

A `param` is a required parameter (defaults may be used). A `field` is not
allowed to be passed to the constructor.

Note that the `has` function is still available, even if it's not needed.

## `param`

```perl
param name => ( isa => NonEmptyStr );
```

A similar function to Moose's `has`. A `param` is required. You may pass it
to the contructor, or use a `default` or `builder` to supply this value.

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
);
```

Note that `field`, like `param`, defaults to read-only, `is => 'ro'`.
You can override this:

```perl
field some_data => ( is => 'rw', isa => NonEmptyStr );
```

Otherwise, it behaves like `has`. You can pass in any arguments that `has`
accepts.

**WARNING**: if you pass in `init_arg`, that will be ignored. A `field` is
just for instance data the class uses. It's not to be passed to the
constructor. If you want that, just use `param`.

# RELATED MODULED

## `MooseX::Extreme::Types`

\* [MooseX::Extreme::Types](https://metacpan.org/pod/MooseX%3A%3AExtreme%3A%3ATypes) is included in the distribution.

# TODO

Some of this may just be wishful thinking. Some of this would be interesting if
others would like to collaborate.

## Roles

We need `MooseX::Extreme::Roles` for completeness. They would also offer the
`param` and `field` functions.

It might be interesting to automatically include something like
`MooseX::Role::Strict`, but with warnings instead of failures.

## Configurable Types

We provide `MooseX::Extreme::Types` for convenience. It would be even more
convenient if we offered an easier for people to build something like
`MooseX::Extreme::Types::Mine` so they can customize it.

## Immutability

```
__PACKAGE__->meta->make_immutable; # we want this to be optional
```

Try to figure out how to automatically make the class immutable.
`B::Hooks::EndOfScope` did not work because `param` and `field` fire at
runtime, not compile-time, and making the class immutable at the end of scope
fires _before_ `param` and `field` are run.

I thought seriously about making the class mutable in each of those functions
and immutable after, but hey, we don't need that performance hit.

## Configurability

Not everyone wants everything. In particular, using \`MooseX::Extreme\` with
\`DBIx::Class\` will be fatal because the latter allows unknown arguments to
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

# AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
