#!perl

use strict;
use warnings;

use Test::More tests => 7;

use Util::Underscore;

ok \&_::is_open == \&Scalar::Util::openhandle, "_::is_open";

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
