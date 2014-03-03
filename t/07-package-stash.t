#!perl

use strict;
use warnings;

use Test::More tests => 4;

use Util::Underscore;

# fixture
{
    package Foo;
}

my $foo = _::package 'Foo';
my $bar = _::package 'Bar';

isa_ok $foo, 'Package::Stash';
isa_ok $foo, 'Package::Stash';

is $foo->name, 'Foo';
is $bar->name, 'Bar';