package PerlX::Underscore;
#ABSTRACT: Common helper functions without having to import them

=pod

=encoding utf8

=cut

use strict;
use warnings;
no warnings 'once';
use version ();

our $VERSION = version::qv('v0.1.0');

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

=head1 

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

=cut

=head3 _::blessed $object

=head3 _::class $object

Return the class which C<$object> was blessed into.

This is a wrapper around C<Scalar::Util::blessed>.

=cut

*_::class   = \&Scalar::Util::blessed;
*_::blessed = \&Scalar::Util::blessed;

=head3 _::ref_addr $ref

Returns the internal memory address of the reference.

This is a wrapper around C<Scalar::Util::refaddr>.

=cut

*_::ref_addr = \&Scalar::Util::refaddr;

=head3 _::ref_type $ref

Returns the name of the basic Perl type which a reference points to.

This is a wrapper around C<Scalar::Util::reftype>.

=cut

*_::ref_type = \&Scalar::Util::reftype;

=head3 _::ref_weaken $ref

Mutates the reference into a weak reference

This is a wrapper around C<Scalar::Util::weaken>.

=cut

*_::ref_weaken = \&Scalar::Util::weaken;

=head3 _::ref_unweaken $ref

Mutates the reference into a strong reference

This is a wrapper around C<Scalar::Util::unweaken>.

=cut

*_::ref_unweaken = \&Scalar::Util::unweaken;

=head3 _::ref_is_weak $ref

Checks whether a reference is weak or strong.

This is a wrapper around C<Scalar::Util::isweak>.

=cut

*_::ref_is_weak = \&Scalar::Util::isweak;

=head2 List::Util and List::MoreUtils

=cut

=head3 _::reduce { BLOCK } @list

Reduces the list via the operation in the BLOCK.

This is a wrapper around C<List::Util::reduce>.

=cut

*_::reduce = \&List::Util::reduce;

=head3 _::any { PREDICATE } @list

The predicate evaluates to true for at least one item in the C<@list>.

This is a wrapper around C<List::Util::any>.

=cut

*_::any = \&List::Util::any;

=head3 _::all { PREDICATE } @list

The predicate evaluates to true for all items in the C<@list>.

This is a wrapper around C<List::Util::all>.

=cut

*_::all = \&List::Util::all;

=head3 _::none { PREDICATE } @list

The predicate evaluates to true for no items in the C<@list>.

This is a wrapper around C<List::Util::none>.

=cut

*_::none = \&List::Util::none;

=head3 _::first { PREDICATE } @list

Returns the first element in the list where the predicate is true.

This is a wrapper around C<List::MoreUtils::first_value>.

=cut

*_::first = \&List::MoreUtils::first_value;

=head3 _::first_index { PREDICATE } @list

Returns the index of the first element in the list where the predicate is true.

This is a wrapper around C<List::MoreUtils::first_index>.

=cut

*_::first_index = \&List::MoreUtils::first_index;

=head3 _::last { PREDICATE } @list

Returns the last element in the list where the predicate is true.

This is a wrapper around C<List::MoreUtils::last_value>.

=cut

*_::last = \&List::MoreUtils::last_value;

=head3 _::last_index { PREDICATE } @list

Returns the index of the last element in the list where the predicate is true.

This is a wrapper around C<List::MoreUtils::last_index>.

=cut

*_::last_index = \&List::MoreUtils::last_index;

=head3 _::max     @list

=head3 _::max_str @list

Returns the numerically maximal element in the list. C<_::max_str> returns the maximal element according to string comparisions instead.

These are wrappers around C<List::Util::max> and C<List::Util::maxstr>, respectively.

=cut

*_::max     = \&List::Util::max;
*_::max_str = \&List::Util::maxstr;

=head3 _::min     @list

=head3 _::min_str @list

Returns the numerically minimal element in the list. C<_::min_str> returns the minimal element according to string comparisions instead.

These are wrappers around C<List::Util::min> and C<List::Util::minstr>, respectively.

=cut

*_::min     = \&List::Util::min;
*_::min_str = \&List::Util::minstr;

=head3 _::sum 0, @list

Returns the sum of all items. Always specify the neutral element zero to avoid getting C<undef> when the list is empty – unless that is wanted, of course.

This is a wrapper around C<List::Util::sum>.

=cut

*_::sum = \&List::Util::sum;

=head3 _::product @list

Returns the product of all items, and C<1> if the list is empty.

This is a wrapper around C<List::Util::product>.

=cut

*_::product = \&List::Util::product;

=head3 _::pairgrep { PREDICATE } @kvlist

Like C<grep>, but on even-sized key-value lists.

This is a wrapper around C<List::Util::pairgrep>.

=cut

*_::pairgrep = \&List::Util::pairgrep;

=head3 _::pairfirst { PREDICATE } @kvlist

Like C<_::first>, but on even-sized key-value lists.

This is a wrapper around C<List::Util::pairfirst>.

=cut

*_::pairfirst = \&List::Util::pairfirst;

=head3 _::pairmap { BLOCK } @kvlist

Like C<map>, but on even-sized key-value lists.

This is a wrapper around C<List::Util::pairmap>.

=cut

*_::pairmap = \&List::Util::pairmap;

=head3 _::shuffle @list

Randomly reorder the items in the list

This is a wrapper around C<List::Util::shuffle>.

=cut

*_::shuffle = \&List::Util::shuffle;

=head2 Carp

=head3 _::carp "Message"

This is a wrapper around C<Carp::carp>.

=cut

*_::carp = \&Carp::carp;

=head3 _::cluck "Message"

This is a wrapper around C<Carp::cluck>.

=cut

*_::cluck = \&Carp::cluck;

=head3 _::croak "Message"

This is a wrapper around C<Carp::croak>.

=cut

*_::croak = \&Carp::croak;

=head3 _::confess "Message"

This is a wrapper around C<Carp::confess>.

=cut

*_::confess = \&Carp::confess;

=head2 UNIVERSAL

...and other goodies from C<Safe::Isa>

=cut

=head3 _::isa $object, 'Class'

This is a wrapper around C<$Safe::Isa::_isa>.

=cut

*_::isa = $Safe::Isa::_isa;

=head3 _::does $object, 'Role'

This is a wrapper around C<$Safe::Isa::_DOES>.

=cut

*_::does = $Safe::Isa::_DOES;

=head3 _::can $object, 'method'

This is a wrapper around C<$Safe::Isa::_can>.

=cut

*_::can = $Safe::Isa::_can;

=head3 $maybe_object->_::safecall(method => @args)

This is a wrapper around C<$Safe::Isa::_call_if_object>.

=cut

*_::safecall = $Safe::Isa::_call_if_object;

1;
