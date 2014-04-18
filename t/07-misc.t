#!perl
use strict;
use warnings;

use Test::More tests => 2;

use Util::Underscore;

subtest 'identity tests' => sub {
    plan tests => 3;

    ok \&_::is_open == \&Scalar::Util::openhandle, "_::is_open";

    is \&_::pp, \&Data::Dump::pp, "_::pp";
    is \&_::dd, \&Data::Dump::dd, "_::dd";
};

sub foo { die "unimplemented" }
my $foo = sub { die "unimplemented" };

subtest '_::prototype' => sub {
    plan tests => 6;

    ok + (not defined _::prototype \&foo), 'sub prototype empty';
    ok + (not defined _::prototype $foo), 'coderef prototype empty';

    _::prototype \&foo, '$;\@@';
    _::prototype $foo, '$;\@@';

    is + (_::prototype \&foo), '$;\@@', 'sub prototype not empty';
    is + (_::prototype $foo), '$;\@@', 'coderef prototype not empty';

    _::prototype \&foo, undef;
    _::prototype $foo, undef;

    ok + (not defined _::prototype \&foo), 'sub prototype empty again';
    ok + (not defined _::prototype $foo), 'coderef prototype empty again';
};
