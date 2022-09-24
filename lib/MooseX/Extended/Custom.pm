package MooseX::Extended::Custom;

# ABSTRACT: Build a custom Moose, just for you.

use 5.20.0;
use strict;
use warnings;
use true;
use MooseX::Extended::Core qw(
  _enabled_features
  _disabled_warnings
);
use MooseX::Extended ();
use namespace::autoclean;

our $VERSION = '0.33';

sub import {
    my @caller       = caller(0);
    my $custom_moose = $caller[0];    # this is our custom Moose definition
    true->import::into($custom_moose) unless $caller[1] =~ /^\(eval/;
    strict->import::into($custom_moose);
    warnings->import::into($custom_moose);
    namespace::autoclean->import::into($custom_moose);
    feature->import( _enabled_features() );
    warnings->unimport(_disabled_warnings);
}

sub create {
    my ( $class, %args ) = @_;
    my $target_class = caller(1);     # this is the class consuming our custom Moose
    MooseX::Extended->import(
        %args,
        call_level => 1,
        for_class  => $target_class,
    );
}

1;

__END__

=head1 SYNOPSIS

Define your own version of L<MooseX::Extended>:

    package My::Moose {
        use MooseX::Extended::Custom;

        sub import {
            my ( $class, %args ) = @_;
            MooseX::Extended::Custom->create(
                excludes => [qw/ StrictConstructor c3 /],
                includes => ['multi'],
                %args    # you need this to allow customization of your customization
            );
        }
    }

    # no need for a true value

And then use it:

    package Some::Class {
        use My::Moose types => [qw/ArrayRef Num/];

        param numbers ( isa => ArrayRef[Num] );

        multi sub foo ($self)       { ... }
        multi sub foo ($self, $bar) { ... }
    }

=head1 DESCRIPTION

I hate boilerplate, so let's get rid of it. Let's say you don't want L<namespace::autoclean> or
C<carp>, but you do want C<multi>. Plus, you have custom versions of C<carp> and C<croak>:

    package Some::Class {
        use MooseX::Extended
          excludes => [qw/ autoclean carp /],
          includes => ['multi'];
        use My::Carp q(carp croak);

        ... my code here
    }

You probably get tired of typing that every time. Now you don't have to. 

    package My::Moose {
        use MooseX::Extended::Custom;
        use My::Carp ();
        use Import::Into;

        sub import {
            my ( $class, %args ) = @_;
            my $target_class = caller;
            MooseX::Extended::Custom->create(
                excludes => [qw/ autoclean carp /],
                includes => ['multi'],
                %args    # you need this to allow customization of your customization
            );
            My::Carp->import::into($target_class, qw(carp croak));
        }
    }

And then when you use C<My::Moose>, that's all set up for you.

If you need to change this on a "per class" basis:

    use My::Moose
      excludes => ['carp'],
      types    => [qw/ArrayRef Num/];

The above changes your C<excludes> and adds C<types>, but doesn't change your C<includes>.
