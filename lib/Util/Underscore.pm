package Util::Underscore;
#ABSTRACT: Common helper functions without having to import them

use strict;
use warnings;
no warnings 'once';

use version 0.77 (); our $VERSION = version->declare('v1.0.0');

use Scalar::Util    1.36        ();
use List::Util      1.35        ();
use List::MoreUtils 0.07        ();
use Carp                        ();
use Safe::Isa       1.000000    ();
use Try::Tiny                   ();

=pod

=encoding utf8

=head1 SYNOPSIS

    use Util::Underscore;
    
    _::croak "$foo must do Some::Role" if not _::does($foo, 'Some::Role');
    

=head1 DESCRIPTION

This module contains various utility functions, and makes them accessible through the C<_> package.
This allows the use of these utilities (a) without much per-usage overhead and (b) without namespace pollution.

It contains functions from the following modules:

=for :list
* L<Scalar::Util>
* L<List::Util>
* L<List::MoreUtils>
* L<Carp>
* L<Safe::Isa>, which contains convenience functions for L<UNIVERSAL>
* L<Try::Tiny>

Not all functions from those are available, and some have been renamed.

=cut

BEGIN {
    # check if a competing "_" exists
    if (keys %{_::}) {
        Carp::confess qq(The package "_" has already been defined);
    }
}

BEGIN {
    # prevent other "_" packages from being loaded:
    # Just setting the ${INC} entry would fail too silently,
    # so we also rigged the "import" method.
    
    $INC{'_.pm'} = *_::import = sub {
        Carp::confess qq(The "_" package is internal to Util::Underscore)
                    . qq(and must not be imported directly.\n);
    };
}

=head1 FUNCTION REFERENCE

=cut

=head2 Scalar::Util

=begin :list

= C<$str = _::blessed $object>
= C<$str = _::class $object>
wrapper for C<Scalar::Util::blessed>

= C<$int = _::ref_addr $ref>
wrapper for C<Scalar::Util::refaddr>

= C<$str = _::ref_type $ref>
wrapper for C<Scalar::Util::reftype>

= C<_::ref_weaken $ref>
wrapper for C<Scalar::Util::weaken>

= C<_::ref_unweaken $ref>
wrapper for C<Scalar::Util::unweaken>

= C<$bool = _::ref_is_weak $ref>
wrapper for C<Scalar::Util::isweak>

= C<$scalar = _::new_dual $num, $str>
wrapper for C<Scalar::Util::dualvar>

= C<$bool = _::is_dual $scalar>
wrapper for C<Scalar::Util::isdual>

= C<$bool = _::is_vstring $scalar>
wrapper for C<Scalar::Util::isvstring>

= C<$bool = _::is_numeric $scalar>
wrapper for C<Scalar::Util::looks_like_number>

= C<$fh = _::is_open $fh>
wrapper for C<Scalar::Util::openhandle>

= C<$bool = _::is_readonly $scalar>
wrapper for C<Scalar::Util::readonly>

= C<$str = _::prototype \&code>
= C<_::prototype \&code, $new_proto>
gets or sets the prototype, wrapping either C<CORE::prototype> or C<Scalar::Util::set_prototype>

= C<$bool = _::is_tainted $scalar>
wrapper for C<Scalar::Util::tainted>

=end :list

=cut

*_::class   = \&Scalar::Util::blessed;
*_::blessed = \&Scalar::Util::blessed;

*_::ref_addr = \&Scalar::Util::refaddr;

*_::ref_type = \&Scalar::Util::reftype;

*_::ref_weaken = \&Scalar::Util::weaken;

*_::ref_unweaken = \&Scalar::Util::unweaken;

*_::ref_is_weak = \&Scalar::Util::isweak;

*_::new_dual = \&Scalar::Util::dualvar;

*_::is_dual = \&Scalar::Util::isdual;

*_::is_vstring = \&Scalar::Util::isvstring;

*_::is_numeric = \&Scalar::Util::looks_like_number;

*_::is_open = \&Scalar::Util::openhandle;

*_::is_readonly = \&Scalar::Util::readonly;

sub _::prototype ($;$) {    ## no critic ProhibitSubroutinePrototypes
    if (@_ == 2) {
        goto &Scalar::Util::set_prototype if @_ == 2;
    }
    if (@_ == 1) {
        my ($coderef) = @_;
        return prototype $coderef;
    }
    else {
        Carp::confess '_::prototype(&;$) takes exactly one or two arguments';
    }
}

*_::is_tainted = \&Scalar::Util::tainted;

=head2 List::Util and List::MoreUtils

=begin :list

= C<$scalar = _::reduce { BLOCK } @list>
wrapper for C<List::Util::reduce>

= C<$bool = _::any { PREDICATE } @list>
wrapper for C<List::Util::any>

= C<$bool = _::all { PREDICATE } @list>
wrapper for C<List::Util::all>

= C<$bool = _::none { PREDICATE } @list>
wrapper for C<List::Util::none>

= C<$scalar = _::first { PREDICATE } @list>
wrapper for C<List::MoreUtils::first_value>

= C<$int = _::first_index { PREDICATE } @list>
wrapper for C<List::MoreUtils::first_index>

= C<$scalar = _::last { PREDICATE } @list>
wrapper for C<List::MoreUtils::last_value>

= C<$int = _::last_index { PREDICATE } @list>
wrapper for C<List::MoreUtils::last_index>

= C<$num = _::max     @list>
= C<$str = _::max_str @list>
wrappers for C<List::Util::max> and C<List::Util::maxstr>, respectively.

= C<$num = _::min     @list>
= C<$str = _::min_str @list>
wrappers for C<List::Util::min> and C<List::Util::minstr>, respectively.

= C<$num = _::sum 0, @list>
wrapper for C<List::Util::sum>

= C<$num = _::product @list>
wrapper for C<List::Util::product>

= C<%kvlist = _::pairgrep { PREDICATE } %kvlist>
wrapper for C<List::Util::pairgrep>

= C<($k, $v) = _::pairfirst { PREDICATE } %kvlist>
wrapper for C<List::Util::pairfirst>

= C<%kvlist = _::pairmap { BLOCK } %kvlist>
wrapper for C<List::Util::pairmap>

= C<@list = _::shuffle @list>
wrapper for C<List::Util::shuffle>

= C<$iter = _::natatime $size, @list>
wrapper for C<List::MoreUtils::natatime>

= C<@list = _::zip \@array1, \@array2, ...>
wrapper for C<List::MoreUtils::zip>

Unlike C<List::MoreUtils::zip>, this function directly takes I<array
references>, and not array variables. It still uses the same implementation.
This change makes it easier to work with anonymous arrayrefs, or other data that
isn't already inside a named array variable.

= C<@list = _::uniq @list>
wrapper for C<List::MoreUtils::uniq>

= C<@list = _::part { INDEX_FUNCTION } @list>
wrapper for C<List::MoreUtils::part>

= C<$iter = _::each_array \@array1, \@array2, ...>
wrapper for C<List::MoreUtils::each_arrayref>

=end :list

=cut

*_::reduce = \&List::Util::reduce;

*_::any = \&List::Util::any;

*_::all = \&List::Util::all;

*_::none = \&List::Util::none;

*_::first = \&List::MoreUtils::first_value;

*_::first_index = \&List::MoreUtils::first_index;

*_::last = \&List::MoreUtils::last_value;

*_::last_index = \&List::MoreUtils::last_index;

*_::max     = \&List::Util::max;
*_::max_str = \&List::Util::maxstr;

*_::min     = \&List::Util::min;
*_::min_str = \&List::Util::minstr;

*_::sum = \&List::Util::sum;

*_::product = \&List::Util::product;

*_::pairgrep = \&List::Util::pairgrep;

*_::pairfirst = \&List::Util::pairfirst;

*_::pairmap = \&List::Util::pairmap;

*_::shuffle = \&List::Util::shuffle;

*_::natatime = \&List::MoreUtils::natatime;

sub _::zip {
    goto &List::MoreUtils::zip;  # adios, prototypes!
}

*_::uniq = \&List::MoreUtils::uniq;

*_::part = \&List::MoreUtils::part;

*_::each_array= \&List::MoreUtils::each_arrayref;

=head2 Carp

=begin :list

= C<_::carp "Message">
wrapper for C<Carp::carp>

= C<_::cluck "Message">
wrapper for C<Carp::cluck>

= C<_::croak "Message">
wrapper for C<Carp::croak>

= C<_::confess "Message">
wrapper for C<Carp::confess>

=end :list

=cut

*_::carp = \&Carp::carp;

*_::cluck = \&Carp::cluck;

*_::croak = \&Carp::croak;

*_::confess = \&Carp::confess;

=head2 UNIVERSAL

...and other goodies from C<Safe::Isa>

=begin :list

= C<$bool = _::isa $object, 'Class'>
wrapper for C<$Safe::Isa::_isa>

= C<$code = _::can $object, 'method'>
wrapper for C<$Safe::Isa::_can>

= C<$bool = _::does $object, 'Role'>
wrapper for C<$Safe::Isa::_DOES>

= C<< any = $maybe_object->_::safecall(method => @args) >>
wrapper for C<$Safe::Isa::_call_if_object>

=end :list 

=cut

*_::isa = $Safe::Isa::_isa;

*_::does = $Safe::Isa::_DOES;

*_::can = $Safe::Isa::_can;

*_::safecall = $Safe::Isa::_call_if_object;

=head2 Try::Tiny

The following keywords are available:

=for :list
* C<_::try>
* C<_::catch>
* C<_::finally>

They are all direct aliases for their namesakes in C<Try::Tiny>.

=cut

*_::try     = \&Try::Tiny::try;
*_::catch   = \&Try::Tiny::catch;
*_::finally = \&Try::Tiny::finally;

1;
