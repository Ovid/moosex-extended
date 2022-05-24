package Not::Corinna::Role::Created {
    use MooseX::Extended::Role;
    use MooseX::Extended::Types qw(PositiveInt);

    field created => ( isa => PositiveInt, default => sub {time} );
}
