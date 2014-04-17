#!perl

use strict;
use warnings;

use Test::More tests => 9;

use Util::Underscore;

BEGIN {
    package Local::Parent;
    sub meth    { $_[1] }
    sub marker  { }

    package Local::Child;
    push our @ISA, 'Local::Parent';

    package Local::Mock;
    sub meth    { $_[1] }
    sub DOES {
        my ($self, $what) = @_;
        return 1 if $what eq 'Local::Parent';
        return $self->SUPER::DOES($what);
    }

    package Local::Unrelated;
    sub meth    { $_[1] }
}

my %class = (
    parent      => 'Local::Parent',
    child       => 'Local::Child',
    mock        => 'Local::Mock',
    unrelated   => 'Local::Unrelated',
);

my %object;
$object{$_} = bless [] => $class{$_} for keys %class;

subtest 'fixtures' => sub {
    plan tests => 4;

    for (keys %object) {
        is ref $object{$_}, $class{$_}, "instantiation for $_ successful";
    }
};

subtest 'identity tests' => sub {
    plan tests => 2;

    is \&_::blessed,    \&Scalar::Util::blessed,    "_::blessed";
    is \&_::class,      \&Scalar::Util::blessed,    "_::class";
};

subtest '_::class_isa' => sub {
    plan tests => 4;

    ok _::class_isa(    $class{parent},     $class{parent}), "positive parent";
    ok _::class_isa(    $class{child},      $class{parent}), "positive child";
    ok !_::class_isa(   $class{mock},       $class{parent}), "negative mock";
    ok !_::class_isa(   $class{unrelated},  $class{parent}), "negative unrelated";
};

subtest '_::class_does' => sub {
    plan tests => 4;

    ok _::class_does(   $class{parent},     $class{parent}), "positive parent";
    ok _::class_does(   $class{child},      $class{parent}), "positive child";
    ok _::class_does(   $class{mock},       $class{parent}), "positive mock";
    ok !_::class_does(  $class{unrelated},  $class{parent}), "negative unrelated";
};

subtest '_::is_instance' => sub {
    plan tests => 4;

    ok _::is_instance(   $object{parent},     $class{parent}), "positive parent";
    ok _::is_instance(   $object{child},      $class{parent}), "positive child";
    ok _::is_instance(   $object{mock},       $class{parent}), "positive mock";
    ok !_::is_instance(  $object{unrelated},  $class{parent}), "negative unrelated";
};

subtest '_::isa' => sub {
    plan tests => 4;

    ok _::isa(   $object{parent},     $class{parent}), "positive parent";
    ok _::isa(   $object{child},      $class{parent}), "positive child";
    ok !_::isa(  $object{mock},       $class{parent}), "negative mock";
    ok !_::isa(  $object{unrelated},  $class{parent}), "negative unrelated";
};

subtest '_::does' => sub {
    plan tests => 4;

    ok _::does(   $object{parent},     $class{parent}), "positive parent";
    ok _::does(   $object{child},      $class{parent}), "positive child";
    ok _::does(   $object{mock},       $class{parent}), "positive mock";
    ok !_::does(  $object{unrelated},  $class{parent}), "negative unrelated";
};

subtest '_::can' => sub {
    plan tests => 4;

    ok _::can(  $object{parent},        'marker'),  "positive parent";
    ok _::can(  $object{child},         'marker'),  "positive child";
    ok !_::can(  $object{mock},         'marker'),  "negative mock";
    ok !_::can(  $object{unrelated},    'marker'),  "negative unrelated";
};

subtest '_::safecall' => sub {
    plan tests => 6 + (keys %object);

    for (keys %object) {
        is _::safecall($object{$_}, meth => "foo"), "foo", "positive $_";
    }

    ok !defined _::safecall(undef,  meth => "foo"), "negative undef";
    ok !defined _::safecall("bar",  meth => "foo"), "negative undef";
    ok !defined _::safecall(42,     meth => "foo"), "negative undef";

    # However, safecall only asserts that the invocant is an object
    #  * It does not allow packages, and
    #  * it does not check that the invocant will respond to the method
    ok !defined _::safecall($class{parent}, meth => "bar", "foo"), "negative package";
    {
        local $@;
        my $result = eval { _::safecall $object{mock}, marker => "foo" };
        my $error = $@;
        ok !defined $result, "negative nonexistent method";
        like $error, qr/^Can't locate object method "marker" via package/;
    }
};
