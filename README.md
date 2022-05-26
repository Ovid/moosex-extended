# NAME

MooseX::Extended - Extend Moose with safe defaults and useful features

# VERSION

version 0.06

# SYNOPSIS

```perl
package My::Names {
    use MooseX::Extended types => [qw(compile Num NonEmptyStr Str PositiveInt ArrayRef)];
    use List::Util 'sum';

    # the distinction between `param` and `field` makes it easier to
    # see which are available to `new`
    param _name => ( isa => NonEmptyStr, init_arg => 'name' );
    param title => ( isa => Str,         required => 0 );

    # forbidden in the constructor
    field created => ( isa => PositiveInt, default => sub {time} );

    sub name ($self) {
        my $title = $self->title;
        my $name  = $self->_name;
        return $title ? "$title $name" : $name;
    }

    sub add ( $self, $args ) {
        state $check = compile( ArrayRef [ Num, 1 ] );    # at least one number
        ($args) = $check->($args);
        return sum( $args->@* );
    }

    sub warnit ($self) {
        carp("this is a warning");
    }
}
```

# DESCRIPTION

This module is **ALPHA** code.

This class attempts to create a safer version of Moose that defaults to
read-only attributes and is easier to read and write.

It tries to bring some of the lessons learned from [the Corinna project](https://github.com/Ovid/Cor),
while acknowledging that you can't always get what you want (such as
true encapsulation and true methods).

This:

```perl
package My::Class {
    use MooseX::Extended;

    ... your code here
}
```

Is sort of the equivalent to:

```perl
package My::Class {
    use v5.20.0;
    use Moose;
    use MooseX::StrictConstructor;
    use feature qw( signatures postderef postderef_qq);
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

# CONFIGURATION

You may pass an import list to [MooseX::Extended](https://metacpan.org/pod/MooseX%3A%3AExtended).

```perl
use MooseX::Extended
  excludes => [qw/StrictConstructor carp/],      # I don't want these features
  types    => [qw/compile PositiveInt HashRef/]; # I want these type tools
```

## `types`

ALlows you to import any types provided by [MooseX::Extended::Types](https://metacpan.org/pod/MooseX%3A%3AExtended%3A%3ATypes).

This:

```perl
use MooseX::Extended::Role types => [qw/compile PositiveInt HashRef/];
```

Is identical to this:

```perl
use MooseX::Extended::Role;
use MooseX::Extended::Types qw( compile PositiveInt HashRef );
```

## `excludes`

You may find some features to be annoying, or even cause potential bugs (e.g.,
if you have a \`croak\` method, our importing of `Carp::croak` will be a
problem. You can exclude the following:

- `StrictConstructor`

    ```perl
    use MooseX::Extended::Role excludes => ['StrictConstructor'];
    ```

    Excluding this will no longer import `MooseX::StrictConstructor`.

- `autoclean`

    ```perl
    use MooseX::Extended::Role excludes => ['autoclean'];
    ```

    Excluding this will no longer import `namespace::autoclean`.

- `c3`

    ```perl
    use MooseX::Extended::Role excludes => ['c3'];
    ```

    Excluding this will no longer apply the C3 mro.

- `carp`

    ```perl
    use MooseX::Extended::Role excludes => ['carp'];
    ```

    Excluding this will no longer import `Carp::croak` and `Carp::carp`.

- `immutable`

    ```perl
    use MooseX::Extended::Role excludes => ['immutable'];
    ```

    Excluding this will no longer make your class immutable.

- `true`

    ```perl
    use MooseX::Extended::Role excludes => ['carp'];
    ```

    Excluding this will require your module to end in a true value.

# IMMUTABILITY

## Making Your Class Immutable

You no longer need to end your Moose classes with:

```
__PACKAGE__->meta->make_immutable;
```

That prevents further changes to the class and provides some optimizations to
make the code run much faster. However, it's somewhat annoying to type. We do
this for you, via `B::Hooks::AtRuntime`. You no longer need to do this yourself.

## Making Your Instance Immutable

By default, attributes defined via `param` and `field` are read-only.
However, if they contain a reference, you can fetch the reference, mutate it,
and now everyone with a copy of that reference has mutated state.

To handle that, we offer a new `clone => $clone_type` pair for attributes.

See the [MooseX::Extended::Manual::Cloning](https://metacpan.org/pod/MooseX%3A%3AExtended%3A%3AManual%3A%3ACloning) documentation.

# OBJECT CONSTRUCTION

Objection construction for [MooseX::Extended](https://metacpan.org/pod/MooseX%3A%3AExtended) is like Moose, so no
changes are needed.  However, in addition to `has`, we also provide `param`
and `field` attributes, both of which are `is => 'ro'` by default.

The `param` is _required_, whether by passing it to the constructor, or using
`default` or `builder`.

The `field` is _forbidden_ in the constructor and lazy by default.

Here's a short example:

```perl
package Class::Name {
    use MooseX::Extended types => [qw(compile Num NonEmptyStr Str)];

    # these default to 'ro' (but you can override that) and are required
    param _name => ( isa => NonEmptyStr, init_arg => 'name' );
    param title => ( isa => Str,         required => 0 );

    # fields must never be passed to the constructor
    # note that ->title and ->name are guaranteed to be set before
    # this because fields are lazy by default
    field name => (
        isa     => NonEmptyStr,
        default => sub ($self) {
            my $title = $self->title;
            my $name  = $self->_name;
            return $title ? "$title $name" : $name;
        },
    );
}
```

See [MooseX::Extended::Manual::Construction](https://metacpan.org/pod/MooseX%3A%3AExtended%3A%3AManual%3A%3AConstruction) for a full explanation.

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

See [MooseX::Extended::Manual::Shortcuts](https://metacpan.org/pod/MooseX%3A%3AExtended%3A%3AManual%3A%3AShortcuts) for a full explanation.

# INVALID ATTRIBUTE NAMES

The following [Moose](https://metacpan.org/pod/Moose) code will print `WhoAmI`. However, the second attribute
name is clearly invalid.

```perl
package Some::Class {
    use Moose;

    has name   => ( is => 'ro' );
    has '-bad' => ( is => 'ro' );
}

my $object = Some::Class->new( name => 'WhoAmI' );
say $object->name;
```

`MooseX::Extended` will throw a `Moose::Exception::InvalidAttributeDefinition` exception
if it encounters an illegal method name for an attribute.

This also applies to various attributes which allow method names, such as
`clone`, `builder`, `clearer`, `writer`, `reader`, and `predicate`.

# DEBUGGER SUPPORT

When running [MooseX::Extended](https://metacpan.org/pod/MooseX%3A%3AExtended) under the debugger, there are some
behavioral differences you should be aware of.

- Your classes won't be immutable

    Ordinarily, we call `__PACKAGE__->meta->make_immutable` for you. This
    relies on [B::Hooks::AtRuntime](https://metacpan.org/pod/B%3A%3AHooks%3A%3AAtRuntime)'s `after_runtime` function. However, that
    runs too late under the debugger and dies. Thus, we disable this feature under
    the debugger. Your classes may run a bit slower, but hey, it's the debugger!

- `namespace::autoclean` will frustrate you

    It's very frustrating when running under the debugger and doing this:

    ```perl
        13==>       my $total = sum(3,4,5);
        DB<4>
        Undefined subroutine &main::sum called at (eval 423) ...
    ```

    We had removed `namespace::autoclean` when running under the debugger, but
    backed that out: [https://github.com/Ovid/moosex-extreme/issues/11](https://github.com/Ovid/moosex-extreme/issues/11).

# MANUAL

- [MooseX::Extended::Manual::Overview](https://metacpan.org/pod/MooseX%3A%3AExtended%3A%3AManual%3A%3AOverview)
- [MooseX::Extended::Manual::Construction](https://metacpan.org/pod/MooseX%3A%3AExtended%3A%3AManual%3A%3AConstruction)
- [MooseX::Extended::Manual::Shortcuts](https://metacpan.org/pod/MooseX%3A%3AExtended%3A%3AManual%3A%3AShortcuts)
- [MooseX::Extended::Manual::Cloning](https://metacpan.org/pod/MooseX%3A%3AExtended%3A%3AManual%3A%3ACloning)

# RELATED MODULES

- [MooseX::Extended::Types](https://metacpan.org/pod/MooseX%3A%3AExtended%3A%3ATypes) is included in the distribution.

    This provides core types for you.

- [MooseX::Extended::Role](https://metacpan.org/pod/MooseX%3A%3AExtended%3A%3ARole) is included in the distribution.

    `MooseX::Extended`, but for roles.

# TODO

Some of this may just be wishful thinking. Some of this would be interesting if
others would like to collaborate.

## Tests

Tests! Many more tests! Volunteers welcome :)

## Configurable Types

We provide `MooseX::Extended::Types` for convenience, along with the `declare` 
function. We should write up (and test) examples of extending it.

## `BEGIN::Lift`

This idea maybe belongs in `MooseX::Extended::OverKill`, but ...

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
terribly weird inside, but you may wish to note that we use
[B::Hooks::AtRuntime](https://metacpan.org/pod/B%3A%3AHooks%3A%3AAtRuntime) and [true](https://metacpan.org/pod/true). They seem sane, but _caveat emptor_.

This module was originally released on github as `MooseX::Extreme`, but
enough people pointed out that it was not extreme at all. That's why the
repository is [https://github.com/Ovid/moosex-extreme/](https://github.com/Ovid/moosex-extreme/).

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
