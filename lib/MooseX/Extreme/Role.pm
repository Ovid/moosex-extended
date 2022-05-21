package MooseX::Extreme::Role;

# ABSTRACT: MooseX::Extreme roles

use strict;
use warnings;
use Moose::Exporter;
use MooseX::Extreme::Core qw(field param);
use MooseX::Role::WarnOnConflict ();
use Moose::Role;
use Moose::Meta::Role;
use namespace::autoclean ();
use Import::Into;
use true;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.01';

Moose::Exporter->setup_import_methods(
    with_meta => [ 'field', 'param' ],
);

sub init_meta {
    my ( $class, %params ) = @_;

    my $for_class = $params{for_class};
    Carp->import::into($for_class);
    warnings->unimport('experimental::signatures');
    feature->import(qw/signatures :5.22/);
    namespace::autoclean->import::into($for_class);
    true->import;              # no need for `1` at the end of the module
    MooseX::Role::WarnOnConflict->import::into($for_class);
    Moose::Role->init_meta(    ##
        %params,               ##
        metaclass => 'Moose::Meta::Role'
    );
    return $for_class->meta;
}

__END__

=head1 SYNOPSIS

    package Not::Corinna::Role::Created {
        use MooseX::Extreme::Role;
        use MooseX::Extreme::Types qw(PositiveInt);

        field created => ( isa => PositiveInt, default => sub { time } );
    }

Similar to L<MooseX::Extreme>, this provides C<field> and C<param> to the role.

Note that there is no need to add a C<1> at the end of the role.

=HEAD1 IDENTICAL METHOD NAMES IN CLASSES AND ROLES

In L<Moose> if a class defines a method of the name as the method of a role
it's consuming, the role's method is I<silently> discarded. With
L<MooseX::Extreme::Role>, you get a warning. This makes maintenance easier
when to prevent you from accidentally overriding a method.

For example:

    package My::Role {
        use MooseX::Extreme::Role;

        sub name {'Ovid'}
    }

    package My::Class {
        use MooseX::Extreme;
        with 'My::Role';
        sub name {'Bob'}
    }

The above code will still run, but you'll get a very verbose warning:

    The class My::Class has implicitly overridden the method (name) from
    role My::Role. If this is intentional, please exclude the method from
    composition to silence this warning (see Moose::Cookbook::Roles::Recipe2)

To silence the warning, just be explicit about your intent:

    package My::Class {
        use MooseX::Extreme;
        with 'My::Role' => { -excludes => ['name'] };
        sub name {'Bob'}
    }
