package MooseX::Extended::Types;

# ABSTRACT: Keep our type tools organized

use strict;
use warnings;
use Type::Library -base;
use Type::Utils -all;
use Type::Params;    # this gets us compile and compile_named
use Types::Standard qw(
  slurpy
);

our $VERSION = '0.25';
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
        'slurpy',
    );
    our %EXPORT_TAGS = ( all => \@EXPORT_OK );
}

1;

__END__

=head1 SYNOPSIS

    use MooseX::Extended;
    use MooseX::Extended::Types;

    use MooseX::Extended::Types qw(
      ArrayRef
      Dict
      Enum
      HashRef
      InstanceOf
      Str
      compile
    );

As a convenience, if you're using L<MooseX::Extended>, you can do this:

    use MooseX::Extended types => [qw(
      ArrayRef
      Dict
      Enum
      HashRef
      InstanceOf
      Str
      compile
    )];

=head1 DESCRIPTION

A basic set of useful types for C<MooseX::Extended>, as provided by
L<Type::Tiny>. Using these is preferred to using using strings due to runtime
versus compile-time failures. For example:

    # fails at runtime, if ->name is set
    param name => ( isa => 'str' );

    # fails at compile-time
    param name => ( isa => str );

=head1 TYPE LIBRARIES

We automatically include the types from the following:

=over

=item * L<Types::Standard>

=item * L<Types::Common::Numeric>

=item * L<Types::Common::String>

=back

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
