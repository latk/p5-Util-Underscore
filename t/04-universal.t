#!perl

use strict;
use warnings;

use Test::More tests => 4;

use Util::Underscore;

my %mapping = (
    isa     => "_isa",
    does    => "_DOES",
    can     => "_can",
    safecall=> "_call_if_object",
);

while (my ($k, $v) = each %mapping) {
    no strict 'refs';
    ok \&{"_::$k"} == ${"Safe::Isa::$v"}, "\\&_::$k == \$Safe::Isa::$v";
}