#!perl

use strict;
use warnings;

use Test::More tests => 16;

use Util::Underscore;

my %functions = (
    is_ref        => sub { _::is_ref $_,        2, 3 },
    is_scalar_ref => sub { _::is_scalar_ref $_, 2, 3 },
    is_array_ref  => sub { _::is_array_ref $_,  2, 3 },
    is_hash_ref   => sub { _::is_hash_ref $_,   2, 3 },
    is_code_ref   => sub { _::is_code_ref $_,   2, 3 },
    is_glob_ref   => sub { _::is_glob_ref $_,   2, 3 },
    is_regex      => sub { _::is_regex $_,      2, 3 },
    is_plain      => sub { _::is_plain $_,      2, 3 },
    is_int        => sub { _::is_int $_,        2, 3 },
    is_uint       => sub { _::is_uint $_,       2, 3 },
    is_identifier => sub { _::is_identifier $_, 2, 3 },
    is_package    => sub { _::is_package $_,    2, 3 },
);

sub value_matrix_ok {
    my ($names, $values, %results) = @_;
    for my $i (0 .. $#$names) {
        subtest $names->[$i] => sub {
            plan tests => scalar keys %results;
            while (my ($fn, $expected) = each %results) {
                my $code = $functions{$fn} // die "Unknown function $fn";
                local $_ = $values->[$i];
                my ($result) = $code->();
                $result = $result ? 1 : 0;
                is $result, $expected->[$i], $fn;
            }
        };
    }
}

sub FOO { };    # for the glob

value_matrix_ok [qw[ scalar_ref  array_ref   hash_ref    code_ref    ]],
    [ \1, [], {}, sub { } ],
    is_ref        => [ 1, 1, 1, 1 ],
    is_scalar_ref => [ 1, 0, 0, 0 ],
    is_array_ref  => [ 0, 1, 0, 0 ],
    is_hash_ref   => [ 0, 0, 1, 0 ],
    is_code_ref   => [ 0, 0, 0, 1 ],
    is_glob_ref   => [ 0, 0, 0, 0 ],
    is_regex      => [ 0, 0, 0, 0 ],
    is_plain      => [ 0, 0, 0, 0 ],
    is_int        => [ 0, 0, 0, 0 ],
    is_uint       => [ 0, 0, 0, 0 ],
    is_identifier => [ 0, 0, 0, 0 ],
    is_package    => [ 0, 0, 0, 0 ];
value_matrix_ok [qw[ glob_ref    regex   string  integer float   undef]],
    [ \*FOO, qr//, '', 42, 42.3, undef ],
    is_ref        => [ 1, 0, 0, 0, 0, 0 ],
    is_scalar_ref => [ 0, 0, 0, 0, 0, 0 ],
    is_array_ref  => [ 0, 0, 0, 0, 0, 0 ],
    is_hash_ref   => [ 0, 0, 0, 0, 0, 0 ],
    is_code_ref   => [ 0, 0, 0, 0, 0, 0 ],
    is_glob_ref   => [ 1, 0, 0, 0, 0, 0 ],
    is_regex      => [ 0, 1, 0, 0, 0, 0 ],
    is_plain      => [ 0, 0, 1, 1, 1, 0 ],
    is_int        => [ 0, 0, 0, 1, 0, 0 ],
    is_uint       => [ 0, 0, 0, 1, 0, 0 ],
    is_identifier => [ 0, 0, 0, 0, 0, 0 ],
    is_package    => [ 0, 0, 0, 0, 0, 0 ];
value_matrix_ok [qw[ negint  ident   package bad_package      _4      _5  ]],
    [ -42, 'fo_3', "x::y", "x'y", undef, undef ],
    is_ref        => [ 0, 0, 0, 0, 0, 0 ],
    is_scalar_ref => [ 0, 0, 0, 0, 0, 0 ],
    is_array_ref  => [ 0, 0, 0, 0, 0, 0 ],
    is_hash_ref   => [ 0, 0, 0, 0, 0, 0 ],
    is_code_ref   => [ 0, 0, 0, 0, 0, 0 ],
    is_glob_ref   => [ 0, 0, 0, 0, 0, 0 ],
    is_regex      => [ 0, 0, 0, 0, 0, 0 ],
    is_plain      => [ 1, 1, 1, 1, 0, 0 ],
    is_int        => [ 1, 0, 0, 0, 0, 0 ],
    is_uint       => [ 0, 0, 0, 0, 0, 0 ],
    is_identifier => [ 0, 1, 0, 0, 0, 0 ],
    is_package    => [ 0, 1, 1, 0, 0, 0 ];
