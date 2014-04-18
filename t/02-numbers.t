#!perl

use strict;
use warnings;

use Test::More tests => 4;

use Util::Underscore;

subtest 'identity tests' => sub {
    plan tests => 1;
    is \&_::is_numeric, \&Scalar::Util::looks_like_number, "_::is_numeric";
};

BEGIN {

    package Local::Numeric;

    use overload '0+' => sub {
        my ($self) = @_;
        return $$self;
    };

    sub new {
        my ($class, $val) = @_;
        return bless \$val => $class;
    }
}

subtest '_::is_numeric' => sub {
    plan tests => 5;
    my $numy_good = Local::Numeric->new(42);
    my $numy_bad  = Local::Numeric->new("foo");

    subtest 'positive numbers' => sub {
        plan tests => 7;
        ok _::is_numeric 24,           "positive int";
        ok _::is_numeric 24.2,         "positive float";
        ok _::is_numeric "24",         "positive int string";
        ok _::is_numeric "24.2",       "positive float string";
        ok _::is_numeric "2E12",       "positive engineering notation";
        ok _::is_numeric "-02.12E-01", "positive complicated float";
        ok _::is_numeric "042",        "positive not octal";
    };

    subtest 'positive infinity' => sub {
        plan tests => 6;
        ok _::is_numeric "inf",       "positive inf";
        ok _::is_numeric "-inf",      "positive -inf";
        ok _::is_numeric "Inf",       "positive Inf";
        ok _::is_numeric "-Inf",      "positive -Inf";
        ok _::is_numeric "Infinity",  "positive Infinity";
        ok _::is_numeric "-Infinity", "positive -Infinity";
    };

    subtest 'positive NaN' => sub {
        plan tests => 4;
        ok _::is_numeric "nan",  "positive nan";
        ok _::is_numeric "-nan", "positive -nan";
        ok _::is_numeric "NaN",  "positive NaN";
        ok _::is_numeric "-NaN", "positive -NaN";
    };

    subtest 'negative' => sub {
        plan tests => 6;
        ok !_::is_numeric undef,   "negative undef";
        ok !_::is_numeric '',      "negative empty string";
        ok !_::is_numeric "0xFF",  "negative hex";
        ok !_::is_numeric "42abc", "negative trailing letters";
        ok !_::is_numeric "abc",   "negative letters";
        ok !_::is_numeric [], "negative reference";
    };

    subtest 'overloaded objects' => sub {
        plan tests => 2;
        ok !_::is_numeric $numy_bad, "negative overloaded object";
        ok _::is_numeric $numy_good, "positive overloaded object";
    };
};

subtest '_::is_int' => sub {
    plan tests => 14;

    # we currently reject any references and therefore any objects,
    # although an object with numeric overloads might want to pass this test.
    # Whatever, just numify it before passing it to _::is_int:
    #     _::is_int(0 + $object)
    ok _::is_int 0,  "positive zero";
    ok _::is_int 42, "positive number";
    ok _::is_int - 42, "positive negative number";
    ok !_::is_int undef, "negative undef";
    ok !_::is_int '',    "negative empty string";
    ok !_::is_int [], "negative reference";
    ok !_::is_int 42.3,   "negative float";
    ok !_::is_int "1E3",  "negative engineering notation integer";
    ok !_::is_int "0x23", "negative hex";
    ok !_::is_int "abc",  "negative letters";
    ok !_::is_int "NaN",  "negative NaN";
    ok !_::is_int "inf",  "negative inf";
    ok _::is_int,  "positive implicit argument" for 42;
    ok !_::is_int, "negative implicit argument" for undef;
};

subtest '_::is_uint' => sub {
    plan tests => 14;
    ok _::is_uint 0,  "positive zero";
    ok _::is_uint 42, "positive number";
    ok !_::is_uint - 42, "negative negative number";
    ok !_::is_uint undef, "negative undef";
    ok !_::is_uint '',    "negative empty string";
    ok !_::is_uint [], "negative reference";
    ok !_::is_uint 42.3,   "negative float";
    ok !_::is_uint "1E3",  "negative engineering notation integer";
    ok !_::is_uint "0x23", "negative hex";
    ok !_::is_uint "abc",  "negative letters";
    ok !_::is_uint "NaN",  "negative NaN";
    ok !_::is_uint "inf",  "negative inf";
    ok _::is_uint,  "positive implicit argument" for 42;
    ok !_::is_uint, "negative implicit argument" for undef;
};
