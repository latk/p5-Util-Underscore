#!perl

use strict;
use warnings;

use Test::More tests => 8;

use Util::Underscore;

subtest 'identity tests' => sub {
    plan tests => 5;
    is \&_::new_dual,   \&Scalar::Util::dualvar,    "_::new_dual";
    is \&_::is_dual,    \&Scalar::Util::isdual,     "_::is_dual";
    is \&_::is_vstring, \&Scalar::Util::isvstring,  "_::isvstring";
    is \&_::is_readonly,    \&Scalar::Util::readonly,   "_::is_readonly";
    is \&_::is_tainted, \&Scalar::Util::tainted,    "_::is_tainted";
};

subtest 'dualvar' => sub {
    plan tests => 5;
    my $dual = _::new_dual -42, "foo bar";
    ok defined $dual,           "construction successful";
    ok _::is_dual $dual,        "_::is_dual positive";
    ok !_::is_dual -42,         "_::is_dual negative";
    is "$dual", "foo bar",      "stringification";
    is 0+$dual, "-42",          "numification";
};

subtest '_::is_vstring' => sub {
    plan tests => 4;
    ok _::is_vstring v1.2.3,            "positive";
    ok !_::is_vstring "v1.2.3",         "negative string";
    ok !_::is_vstring 1.2,              "negative float";
    ok !_::is_vstring "\x01\x02\x03",   "negative binary string";
};

subtest '_::is_readonly' => sub {
    plan tests => 2;
    my $var = 42;
    ok _::is_readonly 42,       "positive";
    ok !_::is_readonly $var,    "negative";
};

subtest '_::is_tainted' => sub {
    plan skip_all => "sufficiently tested via the identity tests";
};

BEGIN {
    package Local::Stringy;

    use overload '""' => sub {
        my ($self) = @_;
        return $$self;
    };

    sub new {
        my ($class, $val) = @_;
        return bless \$val => $class;
    }
}

subtest '_::is_plain' => sub {
    plan tests => 7;
    my $stringy = Local::Stringy->new("foo");
    ok _::is_plain 42,      "positive number";
    ok _::is_plain "foo",   "positive string";
    ok !_::is_plain [],         "negative ref";
    ok !_::is_plain undef,      "negative undef";
    ok !_::is_plain $stringy,   "negative stringy object";
    ok _::is_plain,     "positive implicit argument" for "foo";
    ok !_::is_plain,    "negative implicit argument" for undef;
};

subtest '_::is_identifier' => sub {
    plan tests => 11;
    ok _::is_identifier 'foo_bar',  "positive plain";
    ok _::is_identifier 'a',        "positive single letter";
    ok _::is_identifier 'a3',       "positive letter and digit";
    ok _::is_identifier '_',        "positive underscore";
    ok _::is_identifier 'Foo',      "positive plain uppercase";
    ok !_::is_identifier '3',           "negative digit";
    ok !_::is_identifier undef,         "negative undef";
    ok !_::is_identifier '',            "negative empty string";
    ok !_::is_identifier 'Foo::Bar',    "negative package name";
    ok _::is_identifier,    "positive implicit argument" for 'foo';
    ok !_::is_identifier,   "negative implicit argument" for undef;
};

subtest '_::is_package' => sub {
    plan tests => 13;
    ok _::is_package 'FooBar',  "positive plain";
    ok _::is_package 'a',       "positive single letter";
    ok _::is_package 'a3',      "positive letter and digit";
    ok _::is_package '_',       "positive underscore";
    ok _::is_package 'Foo::Bar',    "positive composite name";
    ok _::is_package 'Foo::3',      "positive composite name digits";
    ok _::is_package 'A::B::C::D',  "positive composite name long";
    ok !_::is_package undef,        "negative undef";
    ok !_::is_package '',           "negative empty string";
    ok !_::is_package 'Foo::',      "negative trailing colon";
    ok !_::is_package q(Foo'Bar),   "negative single quote separator";
    ok _::is_package,   "positive implicit argument" for 'foo';
    ok !_::is_package,  "negative implicit argument" for undef;
};
