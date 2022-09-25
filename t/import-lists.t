#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests
  name    => 'method',
  version => v5.26.0,
  module  => ['Function::Parameters'];

package My::Import::List {
    use MooseX::Extended types => 'is_PositiveOrZeroInt',
      includes                 => { 'method' => [qw/method fun/] };
    use List::Util 'sum';

    method fac($n) { return _fac($n) }

    fun _fac($n) {
        is_PositiveOrZeroInt($n) or die "Don't do that!";
        return 1 if $n < 2;
        return $n * _fac $n - 1;
    }
}

subtest 'custom import lists' => sub {
    my $thing = My::Import::List->new;
    is $thing->fac(4), 24, 'Our "method" can call a "fun"ction';

    throws_ok { $thing->fac(3.14) } qr/Don't do that!/,
      '... and our type constraint works inside of the fun';
};

done_testing;
