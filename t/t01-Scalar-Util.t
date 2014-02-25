#!perl

use strict;
use warnings;

use Test::More tests => 6;

use PerlX::Underscore;

my %aliases = qw/
    class           blessed
    ref_addr        refaddr
    ref_type        reftype
    ref_weaken      weaken
    ref_unweaken    unweaken
    ref_is_weak     isweak
/;

while (my ($k, $v) = each %aliases) {
    no strict 'refs';
    ok \&{"_::$k"} == \&{"Scalar::Util::$v"}, "_::$k == Scalar::Util::$v";
}

