package MooseX::Extreme::Helpers;
use v5.22.0;
use warnings;
use parent 'Exporter';
use feature 'signatures';
no warnings 'experimental::signatures';
use Carp 'croak';
use Ref::Util 'is_plain_arrayref';

our $VERSION = '0.01';

our @EXPORT_OK = qw(field param);

sub param ( $meta, $name, %opts ) {
    $opts{is}       //= 'ro';
    $opts{required} //= 1;

    # "has [@attributes]" versus "has $attribute"
    foreach my $attr ( is_plain_arrayref($name) ? @$name : $name ) {
        my %options = %opts;    # copy each time to avoid overwriting
        $options{init_arg} //= $attr;
        $meta->add_attribute( $attr, %options );
    }
}

sub field ( $meta, $name, %opts ) {
    $opts{is} //= 'ro';

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

1;
