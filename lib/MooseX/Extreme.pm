package MooseX::Extreme;

# ABSTRACT: Moose on Steroids

use 5.22.0;
use Moose                     ();
use MooseX::StrictConstructor ();
use Moose::Exporter;
use mro                  ();
use feature              ();
use namespace::autoclean ();
use Import::Into;
use Ref::Util 'is_plain_arrayref';
use Carp qw/carp croak confess/;

our $VERSION = '0.01';

Moose::Exporter->setup_import_methods(
    with_meta => [ 'field', 'param' ],
    as_is     => [ \&carp, \&croak ],
    also      => ['Moose'],
);

# Internal method setting up exports. No public
# documentation by design

sub init_meta {
    my ( $class, @args ) = @_;
    my %params    = @args;
    my $for_class = $params{for_class};
    Moose->init_meta(@args);
    MooseX::StrictConstructor->import( { into => $for_class } );
    warnings->unimport('experimental::signatures');
    feature->import(qw/signatures :5.22/);
    namespace::autoclean->import::into($for_class);

    # If we never use multiple inheritance, this should not be needed.
    mro::set_mro( scalar caller(), 'c3' );
}

=head2 C<param>

    param name => ( isa => NonEmptyStr );

A similar function to Moose's C<has>. A C<param> is required. You may pass it
to the contructor, or use a C<default> or C<builder> to supply this value.

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

=cut

sub param {
    my ( $meta, $name, %opts ) = @_;

    $opts{is}       //= 'ro';
    $opts{required} //= 1;

    # "has [@attributes]" versus "has $attribute"
    foreach my $attr ( is_plain_arrayref($name) ? @$name : $name ) {
        my %options = %opts;    # copy each time to avoid overwriting
        $options{init_arg} //= $attr;
        $meta->add_attribute( $attr, %options );
    }
}

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
    );

Note that C<field>, like C<param>, defaults to read-only, C<< is => 'ro' >>.
You can override this:

    field some_data => ( is => 'rw', isa => NonEmptyStr );

Otherwise, it behaves like C<has>. You can pass in any arguments that C<has>
accepts.

B<WARNING>: if you pass in C<init_arg>, that will be ignored. A C<field> is
just for instance data the class uses. It's not to be passed to the
constructor. If you want that, just use C<param>.

=cut

sub field {
    my ( $meta, $name, %opts ) = @_;

    $opts{is} //= 'ro';

    # "has [@attributes]" versus "has $attribute"
    foreach my $attr ( 'ARRAY' eq ref $name ? @$name : $name ) {
        my %options = %opts;    # copy each time to avoid overwriting
        $options{init_arg} = undef;
        $meta->add_attribute( $attr, %options );
    }
}

1;

__END__

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This module is B<EXPERIMENTAL>! All features subject to change.

This class attempts to create a safer version of Moose that defaults to
read-only attributes and is easier to read and write.

It tries to bring some of the lessons learned from L<the Corinna project|https://github.com/Ovid/Cor>,
while acknowledging that you can't always get what you want (such as
true encapsulation and true methods).

This:

    package My::Class {
        use MooseX::Extreme;

        ... your code here
    }

Is sort of the equivalent to:

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

It also exports two functions which are similar to Moose C<has>: C<param> and
C<field>.

A C<param> is a required parameter (defaults may be used). A C<field> is not
allowed to be passed to the constructor.

Note that the C<has> function is still available, even if it's not needed.

=head1 RELATED MODULED

=head2 C<MooseX::Extreme::Types>

* L<MooseX::Extreme::Types> is included in the distribution.

=head1 TODO

Some of this may just be wishful thinking. Some of this would be interesting if
others would like to collaborate.

=head2 Roles

We need C<MooseX::Extreme::Roles> for completeness. They would also offer the
C<param> and C<field> functions.

It might be interesting to automatically include something like
C<MooseX::Role::Strict>, but with warnings instead of failures.

=head2 Configurable Types

We provide C<MooseX::Extreme::Types> for convenience. It would be even more
convenient if we offered an easier for people to build something like
C<MooseX::Extreme::Types::Mine> so they can customize it.

=head2 Immutability

    __PACKAGE__->meta->make_immutable; # we want this to be optional

Try to figure out how to automatically make the class immutable.
C<B::Hooks::EndOfScope> did not work because C<param> and C<field> fire at
runtime, not compile-time, and making the class immutable at the end of scope
fires I<before> C<param> and C<field> are run.

I thought seriously about making the class mutable in each of those functions
and immutable after, but hey, we don't need that performance hit.
 
=head2 Configurability

Not everyone wants everything. In particular, using `MooseX::Extreme` with
`DBIx::Class` will be fatal because the latter allows unknown arguments to
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
