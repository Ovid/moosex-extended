package MooseX::Extreme::Core;

# ABSTRACT: Internal module for MooseX::Extreme

use v5.22.0;
use warnings;
use parent 'Exporter';
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Storable 'dclone';
use Ref::Util 'is_plain_arrayref';
use Carp 'croak';

our $VERSION = '0.01';

our @EXPORT_OK = qw(field param);

sub param ( $meta, $name, %opt_for ) {
    $opt_for{is}       //= 'ro';
    $opt_for{required} //= 1;

    # "has [@attributes]" versus "has $attribute"
    foreach my $attr ( is_plain_arrayref($name) ? @$name : $name ) {
        my %options = %opt_for;    # copy each time to avoid overwriting
        $options{init_arg} //= $attr;
        %options = _finalize_options( $meta, $name, %options );
        debug( "Setting param '$attr'", \%options );
        $meta->add_attribute( $attr, %options );
    }
}

sub field ( $meta, $name, %opt_for ) {
    $opt_for{is} //= 'ro';

    # "has [@attributes]" versus "has $attribute"
    foreach my $attr ( is_plain_arrayref($name) ? @$name : $name ) {
        my %options = %opt_for;    # copy each time to avoid overwriting
        if ( defined( my $init_arg = $options{init_arg} ) ) {
            croak("The 'field.init_arg' must be absent or undef, not '$init_arg'");
        }
        $options{init_arg} = undef;
        $options{lazy} //= 1;

        %options = _finalize_options( $meta, $name, %options );
        debug( "Setting field '$attr'", \%options );
        $meta->add_attribute( $attr, %options );
    }
}

sub _finalize_options ( $meta, $name, %opt_for ) {
    debug("Finalizing options for $name");
    state $shortcut_for = {
        predicate => sub ($value) {"has_$value"},
        clearer   => sub ($value) {"clear_$value"},
        builder   => sub ($value) {"_build_$value"},
        writer    => sub ($value) {"set_$value"},
        reader    => sub ($value) {"get_$value"},
    };

    foreach my $option ( keys $shortcut_for->%* ) {
        no warnings 'numeric';    ## no critic (TestingAndDebugging::ProhibitNoWarning)
        if ( exists $opt_for{$option} && 1 == $opt_for{$option} ) {
            $opt_for{$option} = $shortcut_for->{$option}->($name);
        }
    }
    if ( exists $opt_for{writer} && defined $opt_for{writer} ) {
        $opt_for{is} = 'rw';
    }

    if ( delete $opt_for{clone} ) {
        %opt_for = _add_cloning_method( $meta, $name, %opt_for );
    }

    return %opt_for;
}

sub _add_cloning_method ( $meta, $name, %opt_for ) {

    # here be dragons ...
    debug("Adding cloning for $name");
    my $reader = delete( $opt_for{reader} ) // $name;
    my $writer = delete( $opt_for{writer} ) // $reader;
    my $is     = $opt_for{is};
    $opt_for{is} = 'bare';

    my $reader_method = sub ($self) {
        debug("Calling reader method for $name");
        my $attr  = $meta->get_attribute($name);
        my $value = $attr->get_value($self);
        return ref $value ? dclone($value) : $value;
    };
    my $writer_method = sub ( $self, $new_value ) {
        debug("Calling writer method for $name");
        my $attr = $meta->get_attribute($name);
        $new_value = ref $new_value ? dclone($new_value) : $new_value;
        $attr->set_value( $self, $new_value );
        return $new_value;
    };

    if ( $is eq 'ro' ) {
        debug("Adding read-only reader for $name");
        $meta->add_method( $reader => $reader_method );
    }
    elsif ( $reader ne $writer ) {
        debug("Adding separate readers and writers for $name");
        $meta->add_method( $reader => $reader_method );
        $meta->add_method( $writer => $writer_method );
    }
    else {
        debug("Adding overloaded reader/writer for $name");
        $meta->add_method(
            $reader => sub ( $self, $value = undef ) {
                debug( "Args for overloaded reader/writer for $name", \@_ );
                return @_ == 1
                  ? $self->$reader_method
                  : $self->$writer_method($value);
            }
        );
    }
    return %opt_for;
}

sub debug ( $message, $data = undef ) {
    $MooseX::Extreme::Debug = $MooseX::Extreme::Debug;    # suppress "once" warnings
    return unless $MooseX::Extreme::Debug;
    require Data::Printer;
    if ( 2 == @_ ) {                                      # yup, still want multidispatch
        $data    = Data::Printer::np($data);
        $message = "$message: $data";
    }
    Data::Printer::p( \$message );
}

1;

__END__

=head1 DESCRIPTION

This is not for public consumption. Provides the C<field> and C<param>
functions to L<MooseX::Extreme> and L<MooseX::Extreme::Role>.
