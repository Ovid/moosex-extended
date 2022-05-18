package MooseX::Fields;

use 5.22.0;
use Moose                     ();
use MooseX::StrictConstructor ();
use Moose::Exporter;
use mro                  ();
use feature              ();
use namespace::autoclean ();
use Import::Into;
use Carp qw/carp croak confess/;

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

=head1 NAME

Veure::Moose

=head1 SYNOPSIS

    package Some::Class {
        use Veure::Moose;

        has 'attribute' => ( isa => 'Str' );

        sub some_method($self, $arg) {
            ...
        }
    }

=head1 DESCRIPTION

This class is roughly the equivalent of the following:

    use 5.22.0;
    use Moose;
    use MooseX::StrictConstructor;
    use feature 'signatures';
    no warnings 'experimental::signatures';

    use mro 'c3';

However, all attributes are automatically declared as C<< is => 'ro' >> if no
C<is> argument is supplied to their definition.

As a special case, you can pass the value "1" to C<writer>, C<builder>, and
C<clearer> to create appropriate methods prepended with C<_set>, C<_build>, or
C<_clear>, respectively.

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

Note that private attribute have their writers and clearers set to private.
the builder is always private and, unlike the writer and clearer, will have a
double-underscore (prevents method name clashing for public and private
versions of the same attribute).

See also:
http://blogs.perl.org/users/ovid/2013/09/building-your-own-moose.html
