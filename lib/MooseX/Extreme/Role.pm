package MooseX::Extreme::Role;

# ABSTRACT: MooseX::Extreme roles

use strict;
use warnings;
use MooseX::Extreme::Core qw(field param);
use Moose::Role ();
use Moose::Meta::Role;
use namespace::autoclean ();
use Import::Into;
use true;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.01';

Moose::Exporter->setup_import_methods(
    with_meta => [ 'field', 'param' ],
    also      => ['Moose::Role'],
);

sub init_meta {
    my ( $class, %params ) = @_;

    my $for_class = $params{for_class};
    Carp->import::into($for_class);
    warnings->unimport('experimental::signatures');
    feature->import(qw/signatures :5.22/);
    namespace::autoclean->import::into($for_class);
    true->import;                     # no need for `1` at the end of the module
    return Moose::Role->init_meta(    ##
        %params,                      ##
        metaclass => 'Moose::Meta::Role'
    );
}

1;

__END__

=head1 SYNOPSIS

    package Not::Corinna::Role::Created {
        use MooseX::Extreme::Role;
        use MooseX::Extreme::Types qw(PositiveInt);

        field created => ( isa => PositiveInt, default => sub { time } );
    }

Similar to L<MooseX::Extreme>, this provides C<field> and C<param> to the role.

Note that there is no need to add a C<1> at the end of the role.
