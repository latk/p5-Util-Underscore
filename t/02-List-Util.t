#!perl

use strict;
use warnings;

use Test::More tests => 22;

use PerlX::Underscore;

my %lu_aliases = qw/
    reduce      reduce
    any         any
    all         all
    none        none
    max         max
    max_str     maxstr
    min         min
    min_str     minstr
    sum         sum
    product     product
    pairgrep    pairgrep
    pairfirst   pairfirst
    pairmap     pairmap
    shuffle     shuffle
/;

while (my ($k, $v) = each %lu_aliases) {
    no strict 'refs';
    ok \&{"_::$k"} == \&{"List::Util::$v"}, "_::$k == List::Util::$v";
}

my %lmu_aliases = qw/
    first       first_value
    first_index first_index
    last        last_value
    last_index  last_index
    natatime    natatime
    zip         zip
    uniq        uniq
    part        part
/;

while (my ($k, $v) = each %lmu_aliases) {
    no strict 'refs';
    ok \&{"_::$k"} == \&{"List::MoreUtils::$v"}, "_::$k == List::MoreUtils::$v";
}
