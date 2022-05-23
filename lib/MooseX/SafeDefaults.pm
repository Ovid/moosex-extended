package MooseX::SafeDefaults;

# ABSTRACT: Moose on Steroids

use 5.20.0;
use warnings;
use feature qw(signatures);

use Moose::Exporter;
use Moose                     ();
use MooseX::StrictConstructor ();
use mro                       ();
use namespace::autoclean      ();
use MooseX::SafeDefaults::Core qw(field param);
use B::Hooks::AtRuntime 'after_runtime';
use Import::Into;

no warnings qw(experimental::signatures experimental::postderef);
use true;

our $VERSION = '0.01';

Moose::Exporter->setup_import_methods(
    with_meta => [ 'field', 'param' ],
    also      => ['Moose'],
);

# Internal method setting up exports. No public
# documentation by design

sub init_meta ( $class, %params ) {
    my $for_class = $params{for_class};
    Moose->init_meta(%params);
    MooseX::StrictConstructor->import( { into => $for_class } );
    Carp->import::into($for_class);
    feature->import(qw/signatures postderef :5.20/);
    warnings->unimport(qw/experimental::postderef experimental::signatures/);

    # see perldoc -v '$^P'
    if ($^P) {
        say STDERR "We are running under the debugger. $for_class is not immutable";
    }
    else {
        # we also remove namespace::autoclean because when those symbols get
        # removed from the symbol table, you can't access them under the
        # debugger! Very frustrating
        namespace::autoclean->import::into($for_class);

        # after_runtime is loaded too late under the debugger
        after_runtime { $for_class->meta->make_immutable };
    }
    true->import;    # no need for `1` at the end of the module

    # If we never use multiple inheritance, this should not be needed.
    mro::set_mro( $for_class, 'c3' );
}

1;

__END__

=head1 SYNOPSIS

    package My::Names {
        use MooseX::SafeDefaults;
        use MooseX::SafeDefaults::Types
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

=head1 DESCRIPTION

This module is B<EXPERIMENTAL>! All features subject to change.

This class attempts to create a safer version of Moose that defaults to
read-only attributes and is easier to read and write.

It tries to bring some of the lessons learned from L<the Corinna project|https://github.com/Ovid/Cor>,
while acknowledging that you can't always get what you want (such as
true encapsulation and true methods).

This:

    package My::Class {
        use MooseX::SafeDefaults;

        ... your code here
    }

Is sort of the equivalent to:

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

It also exports two functions which are similar to Moose C<has>: C<param> and
C<field>.

A C<param> is a required parameter (defaults may be used). A C<field> is not
allowed to be passed to the constructor.

Note that the C<has> function is still available, even if it's not needed.

=head1 Immutability

=head2 Making Your Class Immutable

Typically Moose classes should end with this:

    __PACKAGE__->meta->make_immutable;

That prevents further changes to the class and provides some optimizations to
make the code run much faster. However, it's somewhat annoying to type. We do
this for you, via C<B::Hooks::AtRuntime>. You no longer need to do this yourself.

=head2 Immutable Objects

By default, attributes defined via C<param> and C<field> are read-only.
However, if they contain a reference, you can fetch the reference, mutate it,
and now everyone with a copy of that reference has mutated state.
C<MooseX::SafeDefaults> offers B<EXPERIMENTAL> support for cloning, but differently
from how we see it typically done. You can just pass the C<< clone => 1 >>
argument to your attribute and it will be clone with L<Storable>'s C<dclone>
function every time you read or write that attribute, it will be cloned if
it's a reference, ensuring that your object is effectively immutable.

If you prefer, you can also pass a code reference or the name of a method you
will use to clone the object. Each will receive three arguments:
C<< $self, $attribute_name, $value_to_clone >>. Here's a full example, taken
from our test suite.

    package My::Class {
        use MooseX::SafeDefaults;
        use MooseX::SafeDefaults::Types qw(NonEmptyStr HashRef InstanceOf);

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

B<Warning>: setting the value via the constructor for the first time doesn't
clone the data. All other gets and sets will clone it. We need to figure out a
clean, performant solution for this.

=head1 OBJECT CONSTRUCTION

The normal C<new>, C<BUILD>, and C<BUILDARGS> functions work as expected.
However, we apply L<MooseX::StrictConstructor> to avoid this problem:

    my $soldier = Soldier->new(
        name   => $name,
        rank   => $rank,
        seriel => $serial, # should be serial
    );

By default, misspelled arguments to the L<Moose> constructor are silently discarded,
leading to hard-to-diagnose bugs. With L<MooseX::SafeDefaults>, they're a fatal error.

If you need to pass arbitrary "sideband" data, explicitly declare it as such:

    param sideband => ( isa => HashRef, default => sub { {} } );

Naturally, because we bundle C<MooseX::SafeDefaults::Types>, you can do much
finer-grained data validation on that, if needed.

=head1 FUNCTIONS

The following two functions are exported into your namespace.

=head2 C<param>

    param name => ( isa => NonEmptyStr );

A similar function to Moose's C<has>. A C<param> is required. You may pass it
to the constructor, or use a C<default> or C<builder> to supply this value.

The above C<param> definition is equivalent to:

    has name => (
        is       => 'ro',
        isa      => NonEmptyStr,
        required => 1,
    );

If you want a parameter that has no C<default> or C<builder> and can
I<optionally> be passed to the constructor, just use C<< required => 0 >>.

    param title => ( isa => Str, required => 0 );

Note that C<param>, like C<field>, defaults to read-only, C<< is => 'ro' >>.
You can override this:

    param name => ( is => 'rw', isa => NonEmptyStr );

Otherwise, it behaves like C<has>. You can pass in any arguments that C<has>
accepts.

    # we'll make it private, but allow it to be passed to the constructor
    # as `name`
    param _name   => ( isa => NonEmptyStr, init_arg => 'name' );

=head2 C<field>

    field created => ( isa => PositiveInt, default => sub { time } );

A similar function to Moose's C<has>. A C<field> is never allowed to be passed
to the constructor, but you can still use C<default> or C<builder>, as normal.

The above C<field> definition is equivalent to:

    has created => (
        is       => 'ro',
        isa      => PositiveInt,
        init_arg => undef,        # not allowed in the constructor
        default  => sub { time },
        lazy     => 1,
    );

Note that C<field>, like C<param>, defaults to read-only, C<< is => 'ro' >>.
You can override this:

    field some_data => ( is => 'rw', isa => NonEmptyStr );

Otherwise, it behaves like C<has>. You can pass in any arguments that C<has>
accepts.

B<WARNING>: if you pass C<field> an C<init_arg> with a defined value, The code
will C<croak>. A C<field> is just for instance data the class uses. It's not
to be passed to the constructor. If you want that, just use C<param>.

Later, we'll add proper exceptions.

=head3 Lazy Fields

Every C<field> is lazy by default. This is because there's no guarantee the code will call
them, but this makes it very easy for a C<field> to rely on a C<param> value being present.

Every C<param> is not lazy by default, but you can add C<< lazy => 1 >> if you need to.

=head1 ATTRIBUTE SHORTCUTS

When using C<field> or C<param>, we have some attribute shortcuts:

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

These can also be used when you pass an array reference to the function:

    package Point {
        use MooseX::SafeDefaults;
        use MooseX::SafeDefaults::Types qw(Int);

        param [ 'x', 'y' ] => (
            isa     => Int,
            clearer => 1,     # clear_x and clear_y available
            default => 0,
        ) :;
    }

Note that these are I<shortcuts> and they make attributes easier to write and more consistent.
However, you can still use full names:

    field authz_delegate => (
        builder => '_build_my_darned_authz_delegate',
    );

=head2 C<writer>

If an attribute has C<writer> is set to C<1> (the number one), a method
named C<set_$attribute_name> is created.

This:

    param title => (
        isa       => Undef | NonEmptyStr,
        default   => undef,
        writer => 1,
    );

Is the same as this:

    has title => (
        is      => 'rw',                  # we change this from 'ro'
        isa     => Undef | NonEmptyStr,
        default => undef,
        writer  => 'set_title',
    );

=head2 C<reader>

By default, the reader (accessor) for the attribute is the same as the name.
You can always change this:

    has payload => ( is => 'ro', reader => 'the_payload' );

However, if you want to change the reader name

If an attribute has C<reader> is set to C<1> (the number one), a method
named C<get_$attribute_name> is created.

This:

    param title => (
        isa       => Undef | NonEmptyStr,
        default   => undef,
        reader => 1,
    );

Is the same as this:

    has title => (
        is      => 'rw',                  # we change this from 'ro'
        isa     => Undef | NonEmptyStr,
        default => undef,
        reader  => 'get_title',
    );

=head2 C<predicate>

If an attribute has C<predicate> is set to C<1> (the number one), a method
named C<has_$attribute_name> is created.

This:

    param title => (
        isa       => Undef | NonEmptyStr,
        default   => undef,
        predicate => 1,
    );

Is the same as this:

    has title => (
        is        => 'ro',
        isa       => Undef | NonEmptyStr,
        default   => undef,
        predicate => 'has_title',
    );

=head2 C<clearer>

If an attribute has C<clearer> is set to C<1> (the number one), a method
named C<clear_$attribute_name> is created.

This:

    param title => (
        isa     => Undef | NonEmptyStr,
        default => undef,
        clearer => 1,
    );

Is the same as this:

    has title => (
        is      => 'ro',
        isa     => Undef | NonEmptyStr,
        default => undef,
        clearer => 'clear_title',
    );

=head2 C<builder>

If an attribute has C<builder> is set to C<1> (the number one), a method
named C<_build_$attribute_name>.

This:

    param title => (
        isa     =>  NonEmptyStr,
        builder => 1,
    );

Is the same as this:

    has title => (
        is      => 'ro',
        isa     => NonEmptyStr,
        builder => '_build_title',
    );

Obviously, a "private" attribute, such as C<_auth_token> would get a build named
C<_build__auth_token> (note the two underscores between "build" and "auth_token").

=head1 INVALID ATTRIBUTE NAMES

The following L<Moose> code will print C<WhoAmI>. However, the second attribute
name is clearly invalid.

    package Some::Class {
        use Moose;

        has name   => ( is => 'ro' );
        has '-bad' => ( is => 'ro' );
    }

    my $object = Some::Class->new( name => 'WhoAmI' );
    say $object->name;

C<MooseX::SafeDefaults> will throw a C<Moose::Exception::InvalidAttributeDefinition> exception
if it encounters an illegal method name for an attribute.

This also applies to various attributes which allow method names, such as
C<clone>, C<builder>, C<clearer>, C<writer>, C<reader>, and C<predicate>.

=head1 RELATED MODULES

=over 4

=item * L<MooseX::SafeDefaults::Types> is included in the distribution.

This provides core types for you.

=item * L<MooseX::SafeDefaults::Role> is included in the distribution.

C<MooseX::SafeDefaults>, but for roles.

=back

=head1 TODO

Some of this may just be wishful thinking. Some of this would be interesting if
others would like to collaborate.

=head2 Tests

Tests! Many more tests! Volunteers welcome :)

=head2 Configurable Types

We provide C<MooseX::SafeDefaults::Types> for convenience. It would be even more
convenient if we offered an easier for people to build something like
C<MooseX::SafeDefaults::Types::Mine> so they can customize it.
 
=head2 Configurability

Not everyone wants everything. In particular, using C<MooseX::SafeDefaults> with
L<DBIx::Class> will be fatal because the latter allows unknown arguments to
constructors.  Or someone might want their "own" extreme Moose, requiring
C<v5.36.0> or not using the C3 mro. What's the best way to allow this?

=head2 C<BEGIN::Lift>

This idea maybe belongs in C<MooseX::Extremely::Extreme>, but ...

Quite often you see things like this:

    BEGIN { extends 'Some::Parent' }

Or this:

    sub serial_number; # required by a role, must be compile-time
    has serial_number => ( ... );

In fact, there are a variety of Moose functions which would work better if
they ran at compile-time instead of runtime, making them look a touch more
like native functions. My various attempts at solving this have failed, but I
confess I didn't try too hard.

=head1 NOTES

There are a few things you might be interested to know about this module when
evaluating it.

Most of this is written with bog-standard L<Moose>, so there's nothing
terribly weird inside. However, there are a couple of modules which stand out.

We do not need C<< __PACKAGE__->meta->make_immutable >> because we use
L<B::Hooks::AtRuntime>'s C<after_runtime> function to set it.

We do not need a true value at the end of a module because we use L<true>.

=head1 SEE ALSO

=over 4

=item * L<MooseX::Modern|https://metacpan.org/pod/MooseX::Modern>

=item * L<Corinna|https://github.com/Ovid/Cor>

=back
