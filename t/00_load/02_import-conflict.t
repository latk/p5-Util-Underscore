#!perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

use_ok 'PerlX::Underscore';

throws_ok { "_"->import } qr/"_" package is internal to PerlX::Underscore/;
