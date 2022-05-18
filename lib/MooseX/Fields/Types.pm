package MooseX::Fields::Types;

# ABSTRACT: Keep our type tools orgnanized

use strict;
use warnings;
use Type::Library -base;
use Type::Utils -all;
use Type::Params; # this gets us compile and compile_named

our $VERSION = '0.01';
our @EXPORT_OK;

BEGIN {
    extends qw(
      Types::Standard
      Types::Common::Numeric
      Types::Common::String
    );
    push @EXPORT_OK => (
        'compile',          # from Type::Params
        'compile_named',    # from Type::Params
    );
}

1;

__END__

=head1 SYNOPSIS

    package MooseX::Fields::Types;

    use MooseX::Fields::Types qw(
      ArrayRef
      Dict
      Enum
      HashRef
      InstanceOf
      Str
      compile
    );

=head1 DESCRIPTION

This is an internal package for L<AATW::Scan>. It's probably overkill,
but if we want to be more strict later, this gives us the basics.

=head1 TYPE LIBRARIES

We automatically include the types from the following:

=over

=item * L<Types::Standard>

=item * L<Types::Common::Numeric>

=item * L<Types::Common::String>

=back

=head1 CUSTOM TYPES

=head2 C<PackageName>

Matches valid package names.

=head2 C<MethodName>

Matches valid method names.

=head2 C<Directory>

Valid directory name. Generally must be C<\w+> separated by C</>. A single
leading dot is permitted.

=head1 EXTRAS

The following extra functions are exported on demand or if use the C<:all> export tag.

=over

=item * C<compile>

See L<Type::Params>

=item * C<compile_named>

See L<Type::Params>

=item * C<slurpy>

See L<Types::Standard>

=back
