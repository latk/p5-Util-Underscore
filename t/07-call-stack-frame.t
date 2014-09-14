#!perl

use strict;
use warnings;

use Test::More tests => 13;

BEGIN { use_ok 'Util::Underscore::CallStackFrame'; }

my $class = 'Util::Underscore::CallStackFrame';

subtest 'constructor' => sub {
    plan tests => 3;
    
    can_ok $class, 'of';
    isa_ok $class->of(0), $class;
    my $call_depth = 0;
    $call_depth++ while caller $call_depth;
    is_deeply $class->of($call_depth), undef;
};

subtest 'package' => sub {
    plan tests => 1;
    
    is $class->of(0)->package, __PACKAGE__;
};

subtest 'file' => sub {
    plan tests => 1;
    
    is $class->of(0)->file, __FILE__;
};

subtest 'line' => sub {
    plan tests => 1;
    
    is $class->of(0)->line, __LINE__;
};

subtest 'subroutine' => sub {
    plan tests => 3;
    
    local *freddy;
    eval q{ sub freddy { $class->of(0) } };
    die $@ if $@;
    my $anon = sub { $class->of(0) };
    
    is freddy()->subroutine, 'freddy';
    is $anon->()->subroutine, '__ANON__';
    
    my $unknown = \&freddy;
    undef *freddy;
    is $unknown->()->subroutine, '(unknown)';
};

subtest 'has_args' => sub {
    plan tests => 3;
    
    my $sub = sub { $class->of(0) };
    ok not($sub->()->has_args);
    ok $sub->(undef)->has_args;
    my @args = (
        [1, 2],
        { a => 42 },
        undef,
    );
    is_deeply scalar($sub->(@args)->has_args), \@args;
};

subtest 'wantarray' => sub {
    plan tests => 4;
    
    my $obj;
    my $sub = sub { $obj = $class->of(0) };
    
    () = $sub->();
    ok $obj->wantarray;
    
    scalar $sub->();
    ok not($obj->wantarray);
    ok defined $obj->wantarray;
    
    $sub->();
    ok not defined $obj->wantarray;
};

subtest 'is_eval, is_require' => sub {
    plan tests => 12;
    
    my $sub = sub { $class->of(0) };
    my $eval_block = sub { eval { $class->of(0) } };
    my $code = q{ $class->of(0) };
    my $eval_string = sub { eval $code };
    
    ok not($sub->()->is_eval);
    ok $eval_block->()->is_eval();
    ok $eval_string->()->is_eval();
    
    is $eval_block->()->is_eval->source, undef;
    is $eval_string->()->is_eval->source, $code;
    
    ok not($eval_block->()->is_eval->is_require);
    ok not($eval_string->()->is_eval->is_require);
    
    ok not($eval_block->()->is_require);
    ok not($eval_string->()->is_require);
    
    # What follows is a horrible hack to simulate a require without using
    # an external file. Basically. you can put callbacks into `@INC` which are
    # executed when resolving a package name. This handler returns a callback
    # that reads a file in line by line.
    # For more details, read `perldoc -f require`.
    {
        # clear @INC, %INC so that our handler is the only entry
        local *INC;
        
        # add the handler.
        push @INC, sub {
            my (undef, $name) = @_;
            return if $name ne 'Local/Whatever.pm';
            return (
                sub {
                    my (undef, $state) = @_;
                    if (@$state) {
                        $_ = shift @$state;
                        return 1;
                    }
                    else {
                        return 0;
                    }
                },
                [
                    q{package Local::Whatever;},
                    qq{my \$instance = $class->of(0);},
                    q{sub get { $instance };},
                    q{1;}
                ],
            );
        };
        
        # execute the require, which launches the handler.
        require Local::Whatever;
    }
    
    my $obj = Local::Whatever::get();
    ok $obj->is_eval;
    ok $obj->is_eval->is_require;
    ok $obj->is_require;
};

subtest 'hints' => sub {
    plan tests => 1;
    
    my $obj = $class->of(0);
    is_deeply $obj->hints, $^H;
};

subtest 'bitmask' => sub {
    plan tests => 1;
    
    my $obj = $class->of(0);
    is_deeply $obj->bitmask, ${^WARNING_BITS};
};

subtest 'hinthash' => sub {
    plan tests => 1;
    
    my $obj = $class->of(0);
    is_deeply $obj->hinthash, \%^H;
};

subtest 'stack frames obtained correctly' => sub {
    plan tests => 3;
    
    my @frames = Local::TestPackage::bar([__PACKAGE__, __FILE__, __LINE__]);

    for (my $i = 0; $i < @frames; $i++) {
        subtest "frame $i" => sub {
            my ($obj, $package, $file, $line) = @{ $frames[$i] };
            is $obj->package, $package, "expected package";
            is $obj->file,    $file,    "expected file";
            is $obj->line,    $line,    "expected line";
        };
    }
};

{
    package Local::TestPackage;
    sub foo {
        my ($expect_a, $expect_b) = @_;
        return
            [$class->of(0), __PACKAGE__, __FILE__, __LINE__],
            [$class->of(1), @$expect_a],
            [$class->of(2), @$expect_b];
    };
    sub bar {
        return foo([__PACKAGE__, __FILE__, __LINE__], @_);
    }
}