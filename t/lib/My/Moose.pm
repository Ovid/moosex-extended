package My::Moose {
    use MooseX::Extended::Custom;

    sub import {
        my ( $class, %args ) = @_;
        MooseX::Extended::Custom->create(
            excludes   => [qw/ StrictConstructor c3 /],
            includes   => ['multi'],
            %args
        );
    }
}
