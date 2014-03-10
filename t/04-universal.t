#!perl

use strict;
use warnings;

use Test::More tests => 13;

use Util::Underscore;

{
    package Local::Parent;
        sub meth { @_ == 3 }
        sub marker {}
    package Local::Child;
        push @Local::Child::ISA, 'Local::Parent';
    package Local::Mocker;
        sub meth { @_ == 3 }
        sub DOES {
            my ($self, $what) = @_;
            return 1 if $what eq 'Local::Parent';
            goto &SUPER::DOES;
        }
    package Local::Unrelated;
        sub meth { @_ == 3 }
}

my %functions = (
    isa         => sub { _::isa         $_, 'Local::Parent' },
    does        => sub { _::does        $_, 'Local::Parent' },
    can         => sub { _::can         $_, 'marker',       },
    safecall    => sub { _::safecall    $_, meth => 1, 2    },
    class_isa   => sub { _::class_isa   $_, 'Local::Parent' },
    class_does  => sub { _::class_does  $_, 'Local::Parent' },
    is_instance => sub { _::is_instance $_, 'Local::Parent' },
);

sub value_matrix_ok {
    my ($names, $objects, %results) = @_;
    for my $i (0 .. $#$names) {
        subtest $names->[$i] => sub {
            plan tests => scalar keys %results;
            while (my ($fn, $expected) = each %results) {
                local $_ = $objects->[$i];
                my ($result) = $functions{$fn}->();
                $result = $result ? 1 : 0;
                is $result, $expected->[$i], $fn;
            }
        };
    }
}

my $pi = bless [] => 'Local::Parent';
my $ci = bless [] => 'Local::Child';
my $mi = bless [] => 'Local::Mocker';
my $ui = bless [] => 'Local::Unrelated';
my $pp = 'Local::Parent';
my $cp = 'Local::Child';
my $mp = 'Local::Mocker';
my $up = 'Local::Unrelated';

value_matrix_ok
            [qw[  iparent     ichild      imocker     iunrelated ]],
               [ $pi,        $ci,        $mi,        $ui        ],
isa         => [  1,          1,          0,          0         ],
does        => [  1,          1,          1,          0         ],
can         => [  1,          1,          0,          0         ],
safecall    => [  1,          1,          1,          1         ],
safecall    => [  1,          1,          1,          1         ];
value_matrix_ok
            [qw[  pparent     pchild      pmocker     punrelated ]],
               [ $pp,        $cp,        $mp,        $up        ],
isa         => [  0,          0,          0,          0         ],
does        => [  0,          0,          0,          0         ],
can         => [  0,          0,          0,          0         ],
safecall    => [  0,          0,          0,          0         ];
value_matrix_ok
            [qw[  string      number      undef       hash        array   ]],
               [  '',         42,         undef,      {},         []      ],
isa         => [  0,          0,          0,          0,          0       ],
does        => [  0,          0,          0,          0,          0       ],
can         => [  0,          0,          0,          0,          0       ],
safecall    => [  0,          0,          0,          0,          0       ];
