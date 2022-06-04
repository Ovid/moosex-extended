#!/usr/bin/env perl

use Test::Most;
use Module::Load 'load';

BEGIN {
    # do this in a BEGIN  block to exit early. Otherwise, the rest of
    # the code won't even compile if we don't have Syntax::Keyword::Try
    # installed.
    if ( $^V && $^V lt v5.24.0 ) {
        plan skip_all => 'Version v5.24.0 or greater required for multimethod support';
    }
    eval {
        load Syntax::Keyword::Try;
        1;
    } or do {
        my $error = $@ || "<unknown error>";
        plan skip_all => "Could not load Syntax::Keyword::Try $error";
    };
}

package My::Try {
    use MooseX::Extended includes => [qw/try/];

    sub reciprocal ( $self, $num ) {
        try {
            return 1 / $num;
        }
        catch {
            # this was a croak(), but by returning the error message (bad
            # practice, this is just for debugging), I could guarantee that
            # I'm not throwing an error and thus see if the catch was working.
            # Currently, the exception is not trapped.
            return "Could not calculate reciprocal of $num: $@";
        }
    }
}

package My::Try::Role {
    use MooseX::Extended::Role includes => [qw/try/];

    sub reciprocal ( $self, $num ) {
        try {
            return 1 / $num;
        }
        catch {
            # this was a croak(), but by returning the error message (bad
            # practice, this is just for debugging), I could guarantee that
            # I'm not throwing an error and thus see if the catch was working.
            # Currently, the exception is not trapped.
            return "Could not calculate reciprocal of $num: $@";
        }
    }
}

package My::Class::Consuming::The::Role {
    use MooseX::Extended;
    with 'My::Try::Role';
}

my %cases = (
    classes => 'My::Try',
    roles   => 'My::Class::Consuming::The::Role',
);

while ( my ( $name, $class ) = each %cases ) {
    subtest "try in $name" => sub {
        ok my $try = $class->new, "We should be allowed to load $name with try/catch";

        is $try->reciprocal(2), .5, 'Our try block should be able to return a value';

        throws_ok { $try->reciprocal(0); }
        qr/Could not calculate reciprocal of.*Illegal division by zero/,
          '... and our catch block should be able to trap the error';
    };
}

done_testing;
