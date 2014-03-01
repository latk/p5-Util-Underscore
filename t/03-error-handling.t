#!perl

use strict;
use warnings;

use Test::More tests => 4;

use PerlX::Underscore;

for my $sub (qw/carp cluck croak confess/) {
    no strict 'refs';
    ok \&{"_::$sub"} == \&{"Carp::$sub"}, "_::$sub == Carp::$sub";
}
