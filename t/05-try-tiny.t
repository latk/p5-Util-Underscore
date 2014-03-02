#!perl

use strict;
use warnings;

use Test::More tests => 3;

use Util::Underscore;

for my $sub (qw/try catch finally/) {
    no strict 'refs';
    ok \&{"_::$sub"} == \&{"Try::Tiny::$sub"}, "\\&_::$sub == \\&Try::Tiny::$sub";
}