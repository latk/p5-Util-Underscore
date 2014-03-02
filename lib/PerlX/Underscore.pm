package PerlX::Underscore;
#ABSTRACT: Common helper functions without having to import them

=pod

=encoding utf8

=cut

use strict;
use warnings;
no warnings 'once';

use version 0.77 (); our $VERSION = version->declare('v0.1_1');

use Scalar::Util    1.36        ();
use List::Util      1.35        ();
use List::MoreUtils 0.07        ();
use Carp                        ();
use Safe::Isa       1.000000    ();

=head1 SYNOPSIS

    use PerlX::Underscore;
    
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
        Carp::confess qq(The "_" package is internal to PerlX::Underscore)
                    . qq(and must not be imported directly.\n);
    };
}

=head1 FUNCTION REFERENCE

=cut

=head2 Scalar::Util

=begin :list

= _::blessed $object
= _::class $object
wrapper for C<Scalar::Util::blessed>

= _::ref_addr $ref
wrapper for C<Scalar::Util::refaddr>

= _::ref_type $ref
wrapper for C<Scalar::Util::reftype>

= _::ref_weaken $ref
wrapper for C<Scalar::Util::weaken>

= _::ref_unweaken $ref
wrapper for C<Scalar::Util::unweaken>

= _::ref_is_weak $ref
wrapper for C<Scalar::Util::isweak>

=end :list

=cut

*_::class   = \&Scalar::Util::blessed;
*_::blessed = \&Scalar::Util::blessed;

*_::ref_addr = \&Scalar::Util::refaddr;

*_::ref_type = \&Scalar::Util::reftype;

*_::ref_weaken = \&Scalar::Util::weaken;

*_::ref_unweaken = \&Scalar::Util::unweaken;

*_::ref_is_weak = \&Scalar::Util::isweak;

=head2 List::Util and List::MoreUtils

=begin :list

= _::reduce { BLOCK } @list
wrapper for C<List::Util::reduce>

= _::any { PREDICATE } @list
wrapper for C<List::Util::any>

= _::all { PREDICATE } @list
wrapper for C<List::Util::all>

= _::none { PREDICATE } @list
wrapper for C<List::Util::none>

= _::first { PREDICATE } @list
wrapper for C<List::MoreUtils::first_value>

= _::first_index { PREDICATE } @list
wrapper for C<List::MoreUtils::first_index>

= _::last { PREDICATE } @list
wrapper for C<List::MoreUtils::last_value>

= _::last_index { PREDICATE } @list
wrapper for C<List::MoreUtils::last_index>

= _::max     @list
= _::max_str @list
wrappers for C<List::Util::max> and C<List::Util::maxstr>, respectively.

= _::min     @list
= _::min_str @list
wrappers for C<List::Util::min> and C<List::Util::minstr>, respectively.

= _::sum 0, @list
wrapper for C<List::Util::sum>

= _::product @list
wrapper for C<List::Util::product>

= _::pairgrep { PREDICATE } @kvlist
wrapper for C<List::Util::pairgrep>

= _::pairfirst { PREDICATE } @kvlist
wrapper for C<List::Util::pairfirst>

= _::pairmap { BLOCK } @kvlist
wrapper for C<List::Util::pairmap>

= _::shuffle @list
wrapper for C<List::Util::shuffle>

= _::natatime $size, @list
wrapper for C<List::MoreUtils::natatime>

= _::zip @list1, @list2, ...
wrapper for C<List::MoreUtils::zip>

= _::uniq @list
wrapper for C<List::MoreUtils::uniq>

= _::part { INDEX_FUNCTION } @list
wrapper for C<List::MoreUtils::part>

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

*_::zip = \&List::MoreUtils::zip;

*_::uniq = \&List::MoreUtils::uniq;

*_::part = \&List::MoreUtils::part;

=head2 Carp

=begin :list

= _::carp "Message"
wrapper for C<Carp::carp>

= _::cluck "Message"
wrapper for C<Carp::cluck>

= _::croak "Message"
wrapper for C<Carp::croak>

= _::confess "Message"
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

= _::isa $object, 'Class'
wrapper for C<$Safe::Isa::_isa>

= _::can $object, 'method'
wrapper for C<$Safe::Isa::_can>

= _::does $object, 'Role'
wrapper for C<$Safe::Isa::_DOES>

= $maybe_object->_::safecall(method => @args)
wrapper for C<$Safe::Isa::_call_if_object>

=end :list 

=cut

*_::isa = $Safe::Isa::_isa;

*_::does = $Safe::Isa::_DOES;

*_::can = $Safe::Isa::_can;

*_::safecall = $Safe::Isa::_call_if_object;

1;
