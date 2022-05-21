package MooseX::Extreme::Helpers;

# ABSTRACT: Internal module for MooseX::Extreme

use v5.22.0;
use warnings;
use parent 'Exporter';
use feature 'signatures';
no warnings 'experimental::signatures';

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
        %options = _apply_shortcuts( $meta, $name, %options );
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

        %options = _apply_shortcuts( $meta, $name, %options );
        $meta->add_attribute( $attr, %options );
    }
}

sub _apply_shortcuts ( $meta, $name, %opt_for ) {
    state $shortcut_for = {
        predicate => sub ($value) {"has_$value"},
        clearer   => sub ($value) {"clear_$value"},
        builder   => sub ($value) {"_build_$value"},
    };
    foreach my $option ( keys $shortcut_for->%* ) {
        if ( exists $opt_for{$option} && 1 == $opt_for{$option} ) {
            $opt_for{$option} = $shortcut_for->{$option}->($name);
        }
    }
    return %opt_for;
}

1;

__END__

=head1 DESCRIPTION

This is not for public consumption. Provides the C<field> and C<param>
functions to L<MooseX::Extreme> and L<MooseX::Extreme::Role>.
