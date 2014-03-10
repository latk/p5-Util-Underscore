#!perl

use strict;
use warnings;

use Test::More tests => 2;

use Util::Underscore;

is \&_::pp, \&Data::Dump::pp, 'pp';
is \&_::dd, \&Data::Dump::dd, 'dd';