#!perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

use_ok 'Util::Underscore';

throws_ok { eval q{use _; 1} or die $@ } qr/"_" package is internal to Util::Underscore/;
