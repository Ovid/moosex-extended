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
    as_is     => [ \&carp, \&croak, \&confess ],
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

=head2 C<field>

Set up our own version of C<field()>.

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

1;

__END__

=head1 SYNOPSIS

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

=head1 DESCRIPTION

TODO
