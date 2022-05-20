package MooseX::Extreme::Meta"";
 
use Moose;
extends 'Moose::Meta::Role';
 
our $VERSION = 0.05;
 
override apply => sub {
    my ( $self, $other, @args ) = @_;
 
    if ( blessed($other) && $other->isa('Moose::Meta::Class') ) {
        # already loaded
        return MooseX::Meta::Role::Application::ToClass::Strict->new(@args)
          ->apply( $self, $other );
    }
 
    super;
};
 
1;
 
