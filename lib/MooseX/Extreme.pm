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
use Carp qw/carp croak confess/;

our $VERSION = '0.01';

Moose::Exporter->setup_import_methods(
    with_meta => [ 'field', 'param' ],
    as_is     => [ \&carp, \&croak ],
    also      => ['Moose'],
);

=head2 C<init_meta>

Internal method setting up exports. Do not call directly.

=cut

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

Note that C<param>, like C<field>, defaults to read-only, C<< is => 'ro >>.
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
    foreach my $attr ( 'ARRAY' eq ref $name ? @$name : $name ) {
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

Note that C<field>, like C<param>, defaults to read-only, C<< is => 'ro >>.
You can override this:

    field some_data => ( is => 'rw', isa => NonEmptyStr );

Otherwise, it behaves like C<has>. You can pass in any arguments that C<has>
accepts. However, if you pass in C<init_arg>, that will be ignored.

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
            state $check = compile( ArrayRef [Num] );
            ($args) = $check->($args);
            carp("no numbers supplied to add()") unless $args->@*;
            return sum( $args->@* );
        }

        sub warnit ($self) {
            carp("this is a warning");
        }
    }

=head1 DESCRIPTION

This module is B<EXPERIMENTAL>! All features subject to change.

This class attempts to create a "safer" version of Moose that default to
read-only attributes and is easier to read and write.

It's sort of the equivalent to:

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

It also exports two functions which are similar to Moose C<has>: C<param> and C<field>.

A C<param> is a required parameter (defaults may be used). A C<field> is not
allowed to be passed to the constructor.

=head1 TODO

    # :(
    __PACKAGE__->meta->make_immutable; # we want this to be optional

Try to figure out how to automatically make the class immutable.
C<B::Hooks::EndOfScope> did not work because C<param> and C<field> fire at
runtime, not compile-time, and making the class immutable at the end of scope
fires I<before> C<param> and C<field> are run.

I thought seriously about making the class mutable in each of those functions
and immutable after, but hey, we don't need that performance hit.
