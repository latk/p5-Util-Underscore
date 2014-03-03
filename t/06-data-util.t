#!perl

use strict;
use warnings;

use Test::More tests => 8;

use Util::Underscore;

my %aliases = qw/
    is_scalar_ref   is_scalar_ref
    is_array_ref    is_array_ref
    is_hash_ref     is_hash_ref
    is_code_ref     is_code_ref
    is_glob_ref     is_glob_ref
    is_regex        is_rx
    is_plain        is_value
    is_int          is_integer
/;

while (my ($k, $v) = each %aliases) {
    no strict 'refs';
    ok \&{"_::$k"} == \&{"Data::Util::$v"}, "_::$k == Data::Util::$v";
}