package MooseX::Extreme::Core;

# ABSTRACT: Internal module for MooseX::Extreme

use v5.20.0;
use warnings;
use parent 'Exporter';
use Moose::Util 'throw_exception';
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Storable 'dclone';
use Ref::Util qw(
  is_plain_arrayref
  is_coderef
);
use Carp 'croak';

our $VERSION = '0.01';

our @EXPORT_OK = qw(field param);

sub param ( $meta, $name, %opt_for ) {
    $opt_for{is}       //= 'ro';
    $opt_for{required} //= 1;

    # "has [@attributes]" versus "has $attribute"
    foreach my $attr ( is_plain_arrayref($name) ? @$name : $name ) {
        my %options = %opt_for;    # copy each time to avoid overwriting
        unless ( $options{init_arg} ) {
            $attr =~ s/^\+//;      # in case they're overriding a parent class attribute
            $options{init_arg} //= $attr;
        }
        _add_attribute( 'param', $meta, $attr, %options );
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

        _add_attribute( 'field', $meta, $attr, %options );
    }
}

sub _add_attribute ( $attr_type, $meta, $name, %opt_for ) {
    debug("Finalizing options for $name");

    unless ( _is_valid_method_name($name) ) {
        throw_exception(
            'InvalidAttributeDefinition',
            attribute_name => $name,
            class_name     => $meta->name,
            messsage       => "Illegal attribute name, '$name'",
        );
    }

    state $shortcut_for = {
        predicate => sub ($value) {"has_$value"},
        clearer   => sub ($value) {"clear_$value"},
        builder   => sub ($value) {"_build_$value"},
        writer    => sub ($value) {"set_$value"},
        reader    => sub ($value) {"get_$value"},
    };

    OPTION: foreach my $option ( keys $shortcut_for->%* ) {
        next unless exists $opt_for{$option};
        no warnings 'numeric';    ## no critic (TestingAndDebugging::ProhibitNoWarning)
        if ( 1 == length( $opt_for{$option} ) && 1 == $opt_for{$option} ) {
            my $option_name = $shortcut_for->{$option}->($name);
            $opt_for{$option} = $option_name;
        }
        unless ( _is_valid_method_name( $opt_for{$option} ) ) {
            throw_exception(
                'InvalidAttributeDefinition',
                attribute_name => $name,
                class_name     => $meta->name,
                messsage       => "Attribute '$name' has an invalid option name, $option => '$opt_for{$option}'",
            );
        }
    }

    if ( exists $opt_for{writer} && defined $opt_for{writer} ) {
        $opt_for{is} = 'rw';
    }

    %opt_for = _maybe_add_cloning_method( $meta, $name, %opt_for );

    debug( "Setting $attr_type, '$name'", \%opt_for );
    $meta->add_attribute( $name, %opt_for );
}

sub _is_valid_method_name ($name) {
    return if ref $name;
    return $name =~ qr/\A[a-z_]\w*\z/ai;
}

sub _maybe_add_cloning_method ( $meta, $name, %opt_for ) {
    return %opt_for unless my $clone = delete $opt_for{clone};

    no warnings 'numeric';    ## no critic (TestingAndDebugging::ProhibitNoWarning)
    my ( $use_dclone, $use_coderef, $use_method );
    if ( 1 == length($clone) && 1 == $clone ) {
        $use_dclone = 1;
    }
    elsif ( _is_valid_method_name($clone) ) {
        $use_method = 1;
    }
    elsif ( is_coderef($clone) ) {
        $use_coderef = 1;
    }
    else {
        throw_exception(
            'InvalidAttributeDefinition',
            attribute_name => 'clone',
            class_name     => $meta->name,
            messsage       => "Attribute 'clone' has an invalid option value, clone => '$clone'",
        );
    }

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
    if ( 2 == @_ ) {                                      # yup, still want multidispatch
        require Data::Dumper;
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Sortkeys = 1;
        local $Data::Dumper::Terse    = 1;
        $data    = Data::Dumper::Dumper($data);
        $message = "$message: $data";
    }
    say STDERR $message;
}

1;

__END__

=head1 DESCRIPTION

This is not for public consumption. Provides the C<field> and C<param>
functions to L<MooseX::Extreme> and L<MooseX::Extreme::Role>.
