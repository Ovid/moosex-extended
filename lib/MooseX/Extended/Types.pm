package MooseX::Extended::Types;

# ABSTRACT: Keep our type tools organized

use strict;
use warnings;
use Type::Library -base;
use Type::Utils -all;

# there is no :all, so we need to hardcode the list
use Type::Params qw(
  compile
  compile_named
  multisig
  validate
  validate_named
  compile_named_oo
  Invocant
  wrap_subs
  wrap_methods
  ArgsObject
);

# EXPORT_OK, but not :all
use Types::Standard qw(
  slurpy
);

our $VERSION = '0.32';
our @EXPORT_OK;

BEGIN {
    extends qw(
      Types::Standard
      Types::Common::Numeric
      Types::Common::String
    );
    push @EXPORT_OK => (
        @Type::Params::EXPORT, @Type::Params::EXPORT_OK,
    );
    our %EXPORT_TAGS = (
        all      => \@EXPORT_OK,
        Standard => [ Types::Standard->type_names ],
        Numeric  => [ qw/Num Int Bool/, Types::Common::Numeric->type_names ],
        String   => [ qw/Str/,          Types::Common::String->type_names ],
    );
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

You can import them individually or with the C<:Standard> tag:

    use MooseX::Extended::Types types => 'Str';
    use MooseX::Extended::Types types => [ 'Str', 'ArrayRef' ];
    use MooseX::Extended::Types types => ':Standard';

Using the C<:Standard> tag is equivalent to:

    use Types::Standard;

No import list is supplied directly to the module, so non-default type
functions must be asked for by name.

=item * L<Types::Common::Numeric>

You can import them individually or with the C<:Numeric> tag:

    use MooseX::Extended::Types types => 'Int';
    use MooseX::Extended::Types types => [ 'Int', 'NegativeOrZeroNum' ];
    use MooseX::Extended::Types types => ':Numeric';

Using the C<:Numeric> tag is equivalent to:

    use Types::Common::Numeric;

No import list is supplied directly to the module, so non-default type
functions must be asked for by name.

=item * L<Types::Common::String>

You can import them individually or with the C<:String> tag:

    use MooseX::Extended::Types types => 'NonEmptyStr';
    use MooseX::Extended::Types types => [ 'NonEmptyStr', 'UpperCaseStr' ];
    use MooseX::Extended::Types types => ':String';

Using the C<:String> tag is equivalent to:

    use Types::Common::String;

No import list is supplied directly to the module, so non-default type
functions must be asked for by name.

=back

=head1 EXTRAS

The following extra functions are exported on demand or if use the C<:all> export tag.

=over

=item * C<compile>

See L<Type::Params>

=item * C<compile_named>

See L<Type::Params>

=item * C<multisig>

See L<Type::Params>

=item * C<validate>

See L<Type::Params>

=item * C<validate_named>

See L<Type::Params>

=item * C<compile_named_oo>

See L<Type::Params>

=item * C<Invocant>

See L<Type::Params>

=item * C<wrap_subs>

See L<Type::Params>

=item * C<wrap_methods>

See L<Type::Params>

=item * C<ArgsObject>

See L<Type::Params>


=item * C<slurpy>

See L<Types::Standard>

=back
