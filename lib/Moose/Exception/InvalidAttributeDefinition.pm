package Moose::Exception::InvalidAttributeDefinition;

# ABSTRACT: Exceptions for invalid attribute definitions.

use Moose;
extends 'Moose::Exception';
our $VERSION = '0.03';
with 'Moose::Exception::Role::Class';

has 'attribute_name' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    documentation => "The exception is thrown if an attribute name is invalid.",
);

__PACKAGE__->meta->make_immutable;
1;
