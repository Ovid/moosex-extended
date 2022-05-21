package Not::Corinna::Role::Created {
    use MooseX::Extreme::Role;
    use MooseX::Extreme::Types qw(PositiveInt);

    field created => ( isa => PositiveInt, default => sub {time} );
}
