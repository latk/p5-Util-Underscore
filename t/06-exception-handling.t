#!perl

use strict;
use warnings;

use Test::More tests => 2;

use Util::Underscore;

subtest 'Carp identity tests' => sub {
    plan tests => 4;

    for my $sub (qw/carp cluck croak confess/) {
        no strict 'refs';
        ok \&{"_::$sub"} == \&{"Carp::$sub"}, "_::$sub";
    }
};

subtest 'Try::Tiny identity tests' => sub {
    for my $sub (qw/try catch finally/) {
        no strict 'refs';
        ok \&{"_::$sub"} == \&{"Try::Tiny::$sub"}, "_::$sub";
    }
};
