# NAME

MooseX::Extreme - Moose on Steroids

# VERSION

version 0.01

# SYNOPSIS

```perl
package Some::Class {
    use Veure::Moose;

    has 'attribute' => ( isa => 'Str' );

    sub some_method($self, $arg) {
        ...
    }
}
```

# DESCRIPTION

This class is roughly the equivalent of the following:

```perl
use 5.22.0;
use Moose;
use MooseX::StrictConstructor;
use feature 'signatures';
no warnings 'experimental::signatures';

use mro 'c3';
```

However, all attributes are automatically declared as `is => 'ro'` if no
`is` argument is supplied to their definition.

As a special case, you can pass the value "1" to `writer`, `builder`, and
`clearer` to create appropriate methods prepended with `_set`, `_build`, or
`_clear`, respectively.

```perl
has foo => (
    isa     => 'Str',
    writer  => 1,       # set_foo
    builder => 1,       # _build_foo # always private
    clearer => 1,       # clear_foo
);
has _private => (
    isa     => 'Int',
    writer  => 1,       # _set_private
    builder => 1,       # _build__private
    clearer => 1,       # _clear_private
);
```

Note that private attribute have their writers and clearers set to private.
the builder is always private and, unlike the writer and clearer, will have a
double-underscore (prevents method name clashing for public and private
versions of the same attribute).

See also:
http://blogs.perl.org/users/ovid/2013/09/building-your-own-moose.html

## `init_meta`

Internal method setting up exports. Do not call directly.

## `field`

Set up our own version of `field()`.

# NAME

Veure::Moose

# AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
