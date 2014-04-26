#!perl
use strict;
use warnings;

use Test::More tests => 4;

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

subtest '_::Dir' => sub {
    plan tests => 1;

    my $dir = _::Dir "foo/bar", "baz";
    isa_ok $dir, 'Path::Class::Dir';
};

subtest '_::File' => sub {
    plan tests => 1;

    my $file = _::File "foo/bar", "baz.txt";
    isa_ok $file, 'Path::Class::File';
};
