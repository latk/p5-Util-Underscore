#!perl

use strict;
use warnings;

use Test::More tests => 3;

use Util::Underscore;

is \&_::pp, \&Data::Dump::pp, 'pp';
is \&_::dd, \&Data::Dump::dd, 'dd';
local $_ = 'foo\bar' . "\n \x00baz";
is _::quote, q("foo\\\\bar\n \0baz"), 'quote $_';
