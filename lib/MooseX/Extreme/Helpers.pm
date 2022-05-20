package MooseX::Extreme::Helpers {
    use v5.22.0;
    use parent 'Exporter';
    use MooseX::StrictConstructor ();
    use MooseX::HasDefaults::RO   ();
    use mro                       ();
    use namespace::autoclean      ();
    use Import::Into;
    use B::Hooks::AtRuntime 'after_runtime';
    use true;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    use Carp 'croak';
    use Ref::Util 'is_plain_arrayref';

    our $VERSION = '0.01';

    our @EXPORT_OK = qw(field param init_meta);

    sub init_meta {
        my ( $class, @args ) = @_;
        my %params    = @args;
        my $for_class = $params{for_class};
        Moose->init_meta(@args);
        MooseX::StrictConstructor->import( { into => $for_class } );
        MooseX::HasDefaults::RO->import( { into => $for_class } );
        Carp->import::into($for_class);
        warnings->unimport('experimental::signatures');
        feature->import(qw/signatures :5.22/);
        namespace::autoclean->import::into($for_class);
        after_runtime { $for_class->meta->make_immutable };
        true->import;    # no need for `1` at the end of the module

        # If we never use multiple inheritance, this should not be needed.
        mro::set_mro( $for_class, 'c3' );
    }

    sub param ( $meta, $name, %opts ) {
        $opts{required} //= 1;

        # "has [@attributes]" versus "has $attribute"
        foreach my $attr ( is_plain_arrayref($name) ? @$name : $name ) {
            my %options = %opts;    # copy each time to avoid overwriting
            $options{init_arg} //= $attr;
            $meta->add_attribute( $attr, %options );
        }
    }

    sub field ( $meta, $name, %opts ) {

        # "has [@attributes]" versus "has $attribute"
        foreach my $attr ( is_plain_arrayref($name) ? @$name : $name ) {
            my %options = %opts;    # copy each time to avoid overwriting
            if ( defined( my $init_arg = $options{init_arg} ) ) {
                croak(
"The 'field.init_arg' must be absent or undef, not '$init_arg'"
                );
            }
            $options{init_arg} = undef;
            $options{lazy} //= 1;
            $meta->add_attribute( $attr, %options );
        }
    }
}

1;
