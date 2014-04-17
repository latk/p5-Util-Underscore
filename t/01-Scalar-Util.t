#!perl

use strict;
use warnings;

use Test::More tests => 8;

use Util::Underscore;

my %aliases = qw/
    class           blessed
    is_open         openhandle
    /;

while (my ($k, $v) = each %aliases) {
    no strict 'refs';
    ok \&{"_::$k"} == \&{"Scalar::Util::$v"}, "_::$k == Scalar::Util::$v";
}

# Test _::prototype

sub foo { die "unimplemented" }
my $foo = sub { die "unimplemented" };

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
