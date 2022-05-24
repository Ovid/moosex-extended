# PODNAME: MooseX::SafeDefaults::Manual::Cloning
# ABSTRACT: An overview of MooseX::SafeDefaults optional attribute cloning

our $VERSION = '0.01';

=head1 CLONING SUPPORT

C<MooseX::SafeDefaults> offers optional, B<EXPERIMENTAL> support for attribute
cloning, but differently from how we see it typically done. You can just pass
the C<< clone => 1 >> argument to your attribute and it will be clone with
L<Storable>'s C<dclone> function every time you read or write that attribute,
it will be cloned if it's a reference, ensuring that your object is
effectively immutable.

If you prefer, you can also pass a code reference or the name of a method you
will use to clone the object. Each will receive three arguments:
C<< $self, $attribute_name, $value_to_clone >>. Here's a full example, taken
from our test suite.

    package My::Class {
        use MooseX::SafeDefaults;
        use MooseX::SafeDefaults::Types qw(NonEmptyStr HashRef InstanceOf);

        param name => ( isa => NonEmptyStr );

        param payload => (
            isa    => HashRef,
            clone  => 1,  # uses Storable::dclone
            writer => 1,
        );

        param start_date => (
            isa   => InstanceOf ['DateTime'],
            clone => sub ( $self, $name, $value ) {
                return $value->clone;
            },
        );

        param end_date => (
            isa    => InstanceOf ['DateTime'],
            clone  => '_clone_end_date',
        );

        sub _clone_end_date ( $self, $name, $value ) {
            return $value->clone;
        }

        sub BUILD ( $self, @ ) {
            if ( $self->end_date < $self->start_date ) {
                croak("End date must not be before start date");
            }
        }
    }

B<Warning>: setting the value via the constructor for the first time doesn't
clone the data. All other gets and sets will clone it. We need to figure out a
clean, performant solution for this.


