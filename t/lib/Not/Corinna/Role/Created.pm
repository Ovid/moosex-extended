package Not::Corinna::Role::Created {
    use MooseX::SafeDefaults::Role;
    use MooseX::SafeDefaults::Types qw(PositiveInt);

    field created => ( isa => PositiveInt, default => sub {time} );
}
