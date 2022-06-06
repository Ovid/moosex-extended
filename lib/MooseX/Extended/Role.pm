package MooseX::Extended::Role;

# ABSTRACT: MooseX::Extended roles

use strict;
use warnings;
use Moose::Exporter;
use MooseX::Extended::Types ':all';
use MooseX::Extended::Core qw(
  field
  param
  _debug
  _default_import_list
  _enabled_features
  _disabled_warnings
  _apply_optional_features
  _role_excludes
  _our_import
  config_for
);
use MooseX::Role::WarnOnConflict ();
use Moose::Role;
use Moose::Meta::Role;
use Moose::Util 'throw_exception';
use namespace::autoclean ();
use Import::Into;
use true;
use feature _enabled_features();
no warnings _disabled_warnings();

our $VERSION = '0.11';

# Should this be in the metaclass? It feels like it should, but
# the MOP really doesn't support these edge cases.
my %CONFIG_FOR;

sub import {
    my ( $class, %args ) = @_;
    $args{_import_type} = 'role';
    my ( $import, undef, undef ) = Moose::Exporter->setup_import_methods(
        with_meta => [ 'field', 'param' ],
    );
    _our_import( $class, $import, %args );
}

sub init_meta ( $class, %params ) {
    my $for_class = $params{for_class};

    my $config = config_for($for_class);

    if ( $config->{debug} ) {
        $MooseX::Extended::Debug = $config->{debug};
    }

    foreach my $feature (qw/includes excludes/) {
        if ( exists $config->{$feature} ) {
            foreach my $category ( sort keys $config->{$feature}->%* ) {
                _debug("$for_class $feature '$category'");
            }
        }
    }

    _apply_default_features( $config, $for_class, \%params );
    _apply_optional_features( $config, $for_class );
    return $for_class->meta;
}

sub _apply_default_features ( $config, $for_class, $params ) {

    if ( my $types = $config->{types} ) {
        _debug("$for_class: importing types '@$types'");
        MooseX::Extended::Types->import::into( $for_class, @$types );
    }

    Carp->import::into($for_class)                         unless $config->{excludes}{carp};
    namespace::autoclean->import::into($for_class)         unless $config->{excludes}{autoclean};
    true->import                                           unless $config->{excludes}{true};
    MooseX::Role::WarnOnConflict->import::into($for_class) unless $config->{excludes}{WarnOnConflict};

    feature->import( _enabled_features() );
    warnings->unimport(_disabled_warnings);

    Moose::Role->init_meta(    ##
        %$params,              ##
        metaclass => 'Moose::Meta::Role'
    );
}

1;

__END__

=head1 SYNOPSIS

    package Not::Corinna::Role::Created {
        use MooseX::Extended::Role types => ['PositiveInt'];

        field created => ( isa => PositiveInt, default => sub { time } );
    }

Similar to L<MooseX::Extended>, providing almost everything that module provides.
However, for obvious reasons, it does not include L<MooseX::StrictConstructor>
or make your class immutable, or set the C3 mro.

Note that there is no need to add a C<1> at the end of the role.

=head1 CONFIGURATION

You may pass an import list to L<MooseX::Extended::Role>.

    use MooseX::Extended::Role
      excludes => [qw/WarnOnConflict carp/],         # I don't want these features
      types    => [qw/compile PositiveInt HashRef/]; # I want these type tools

=head2 C<types>

Allows you to import any types provided by L<MooseX::Extended::Types>.

This:

    use MooseX::Extended::Role types => [qw/compile PositiveInt HashRef/];

Is identical to this:

    use MooseX::Extended::Role;
    use MooseX::Extended::Types qw( compile PositiveInt HashRef );

=head2 C<excludes>

You may find some features to be annoying, or even cause potential bugs (e.g.,
if you have a `croak` method, our importing of C<Carp::croak> will be a
problem. You can exclude the following:

=over 4

=item * C<WarnOnConflict>

    use MooseX::Extended::Role excludes => ['WarnOnConflict'];

Excluding this removes the C<MooseX::Role::WarnOnConflict> role.

=item * C<autoclean>

    use MooseX::Extended::Role excludes => ['autoclean'];

Excluding this will no longer import C<namespace::autoclean>.

=item * C<carp>

    use MooseX::Extended::Role excludes => ['carp'];

Excluding this will no longer import C<Carp::croak> and C<Carp::carp>.

=item * C<true>

    use MooseX::Extended::Role excludes => ['carp'];

Excluding this will require your module to end in a true value.

=back

=head2 C<includes>

Some experimental features are useful, but might not be quite what you want.

=over 4

=item * C<multi>

    use MooseX::Extended::Role includes => [qw/multi/];

    multi sub foo ($self, $x)      { ... }
    multi sub foo ($self, $x, $y ) { ... }

Allows you to redeclare a method (or subroutine) and the dispatch will use the number
of arguments to determine which subroutine to use. Note that "slurpy" arguments such as
arrays or hashes will take precedence over scalars:

    multi sub foo ($self, @x) { ... }
    multi sub foo ($self, $x) { ... } # will never be called

Only available on Perl v5.26.0 or higher. Requires L<Syntax::Keyword::MultiSub>.

=item * C<async>

    package My::Thing {
        use MooseX::Extended
        types    => [qw/Str/],
        includes => ['async'];
        use IO::Async::Loop;

        field output => ( is => 'rw', isa => Str, default => '' );

        async sub doit ( $self, @list ) {
            my $loop = IO::Async::Loop->new;
            $self->output('> ');
            foreach my $item (@list) {
                await $loop->delay_future( after => 0.01 );
                $self->output( $self->output . "$item " );
            }
        }
    }

Allows you to write asynchronous code with C<async> and C<await>.

Only available on Perl v5.26.0 or higher. Requires L<Future::AsyncAwait>.

=back

=head1 IDENTICAL METHOD NAMES IN CLASSES AND ROLES

In L<Moose> if a class defines a method of the name as the method of a role
it's consuming, the role's method is I<silently> discarded. With
L<MooseX::Extended::Role>, you get a warning. This makes maintenance easier
when to prevent you from accidentally overriding a method.

For example:

    package My::Role {
        use MooseX::Extended::Role;

        sub name {'Ovid'}
    }

    package My::Class {
        use MooseX::Extended;
        with 'My::Role';
        sub name {'Bob'}
    }

The above code will still run, but you'll get a very verbose warning:

    The class My::Class has implicitly overridden the method (name) from
    role My::Role. If this is intentional, please exclude the method from
    composition to silence this warning (see Moose::Cookbook::Roles::Recipe2)

To silence the warning, just be explicit about your intent:

    package My::Class {
        use MooseX::Extended;
        with 'My::Role' => { -excludes => ['name'] };
        sub name {'Bob'}
    }
