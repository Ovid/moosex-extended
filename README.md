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

    param _name   => ( isa => NonEmptyStr, init_arg => 'name' );
    param title   => ( isa => Str,         required => 0 );
    field created => ( isa => PositiveInt, default  => sub { time } );

    sub name ($self) {
        my $title = $self->title;
        my $name  = $self->_name;
        return $title ? "$title $name" : $name;
    }

    sub add ( $self, $args ) {
        state $check = compile( ArrayRef [Num] );
        ($args) = $check->($args);
        carp("no numbers supplied to add()") unless $args->@*;
        return sum( $args->@* );
    }

    sub warnit ($self) {
        carp("this is a warning");
    }
}
```

# DESCRIPTION

TODO

## `init_meta`

Internal method setting up exports. Do not call directly.

## `field`

Set up our own version of `field()`.

# AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
