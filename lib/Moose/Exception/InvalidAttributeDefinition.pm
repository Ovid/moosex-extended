package Moose::Exception::InvalidAttributeDefinition;

# ABSTRACT: MooseX::Extended exception for invalid attribute definitions.

use Moose;
extends 'Moose::Exception';
our $VERSION = '0.07';
with 'Moose::Exception::Role::Class';

has 'attribute_name' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    documentation => "The exception is thrown if an attribute name is invalid.",
);

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 WHY NOT MOOSEX?

This is not called C<MooseX::Exception::InvalidAttributeDefinition> because
L<Moose::Util>'s C<throw_exception> function assumes that all exceptions begin
with C<Moose::Exception::>.
