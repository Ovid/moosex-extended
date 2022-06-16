package Moose::Exception::InvalidImportList;

# ABSTRACT: MooseX::Extended exception for import arguments.

use Moose;
extends 'Moose::Exception';
use MooseX::Extended::Types qw(NonEmptyStr PositiveInt);
our $VERSION = '0.26';
with 'Moose::Exception::Role::Class';

has 'moosex_extended_type' => (
    is            => 'ro',
    isa           => NonEmptyStr,
    required      => 1,
    documentation => "The name of the MooseX::Extended package called with the invalid import list.",
);

has 'line_number' => (
    is            => 'ro',
    isa           => PositiveInt,
    required      => 1,
    documentation => "The line number of the code throwing the exception.",
);

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 WHY NOT MOOSEX?

This is not called C<MooseX::Exception::InvalidImportList> because
L<Moose::Util>'s C<throw_exception> function assumes that all exceptions begin
with C<Moose::Exception::>.
