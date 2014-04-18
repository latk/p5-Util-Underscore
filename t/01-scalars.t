#!perl -T

use strict;
use warnings;

use Test::More tests => 8;

use Util::Underscore;

subtest 'identity tests' => sub {
    plan tests => 1;
    is \&_::new_dual, \&Scalar::Util::dualvar, "_::new_dual";
};

subtest 'dualvar' => sub {
    plan tests => 7;

    my $dual = _::new_dual - 42, "foo bar";
    ok defined $dual, "construction successful";

    ok _::is_dual $dual, "_::is_dual positive";
    ok !_::is_dual - 42, "_::is_dual negative";
    ok _::is_dual,  "_::is_dual positive default argument" for $dual;
    ok !_::is_dual, "_::is_dual negative default argument" for -42;

    is "$dual", "foo bar", "stringification";
    is 0 + $dual, "-42", "numification";
};

subtest '_::is_vstring' => sub {
    plan tests => 7;

    ok _::is_vstring v1.2.3, "positive";

    ok !_::is_vstring undef,          "negative undef";
    ok !_::is_vstring "v1.2.3",       "negative string";
    ok !_::is_vstring 1.2,            "negative float";
    ok !_::is_vstring "\x01\x02\x03", "negative binary string";

    ok _::is_vstring,  "positive default argument" for v1.2.3;
    ok !_::is_vstring, "negative default argument" for undef;
};

subtest '_::is_readonly' => sub {
    plan tests => 4;
    my $var = 42;
    ok _::is_readonly 42, "positive";
    ok !_::is_readonly $var, "negative";
    ok _::is_readonly,  "positive default argument" for 42;
    ok !_::is_readonly, "negative default argument" for $var;
};

subtest '_::is_tainted' => sub {
    plan tests => 4;

    my ($taint_key) = keys %ENV;
    my $tainted     = $ENV{$taint_key};
    my $untainted   = 42;

    ok _::is_tainted $tainted,    "positive variable";
    ok !_::is_tainted $untainted, "negative variable";
    ok _::is_tainted,  "positive implicit argument" for $tainted;
    ok !_::is_tainted, "negative implicit argument" for $untainted;
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
    ok _::is_plain 42,    "positive number";
    ok _::is_plain "foo", "positive string";
    ok !_::is_plain [], "negative ref";
    ok !_::is_plain undef, "negative undef";
    ok !_::is_plain $stringy, "negative stringy object";
    ok _::is_plain,  "positive implicit argument" for "foo";
    ok !_::is_plain, "negative implicit argument" for undef;
};

subtest '_::is_identifier' => sub {
    plan tests => 11;
    ok _::is_identifier 'foo_bar',   "positive plain";
    ok _::is_identifier 'a',         "positive single letter";
    ok _::is_identifier 'a3',        "positive letter and digit";
    ok _::is_identifier '_',         "positive underscore";
    ok _::is_identifier 'Foo',       "positive plain uppercase";
    ok !_::is_identifier '3',        "negative digit";
    ok !_::is_identifier undef,      "negative undef";
    ok !_::is_identifier '',         "negative empty string";
    ok !_::is_identifier 'Foo::Bar', "negative package name";
    ok _::is_identifier,  "positive implicit argument" for 'foo';
    ok !_::is_identifier, "negative implicit argument" for undef;
};

subtest '_::is_package' => sub {
    plan tests => 13;
    ok _::is_package 'FooBar',     "positive plain";
    ok _::is_package 'a',          "positive single letter";
    ok _::is_package 'a3',         "positive letter and digit";
    ok _::is_package '_',          "positive underscore";
    ok _::is_package 'Foo::Bar',   "positive composite name";
    ok _::is_package 'Foo::3',     "positive composite name digits";
    ok _::is_package 'A::B::C::D', "positive composite name long";
    ok !_::is_package undef,       "negative undef";
    ok !_::is_package '',          "negative empty string";
    ok !_::is_package 'Foo::',     "negative trailing colon";
    ok !_::is_package q(Foo'Bar),  "negative single quote separator";
    ok _::is_package,  "positive implicit argument" for 'foo';
    ok !_::is_package, "negative implicit argument" for undef;
};
