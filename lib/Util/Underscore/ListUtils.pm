package Util::Underscore::ListUtils;

#ABSTRACT: Interface to List::Util and List::MoreUtils

use strict;
use warnings;

## no critic (ProhibitMultiplePackages)
package    # hide from PAUSE
    _;

## no critic (ProhibitSubroutinePrototypes)

=pod

=encoding utf8

=head1 FUNCTION REFERENCE

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

= C<$scalar = _::max_by { BLOCK } @list>
= C<@list   = _::max_by { BLOCK } @list>
= C<$scalar = _::max_str_by { BLOCK } @list>
= C<@list   = _::max_str_by { BLOCK } @list>

Finds the maximum element(s).
However, not the elements themselves but the value returned by the code block is used for sorting.
This makes it unnecessary to sort with a Schwartzian Transform.

This function is context dependent. In void context, it will return immediately.

The C<max_by> variant compares sorting keys numerically, whereas C<max_str_by> uses string comparison.

B<{ BLOCK }>:
the sorting key code block.
The current element will be aliased to C<$_> inside the code block.
The code inside the block should have no side effects, because it's not guaranteed how often the block will be executed.

B<@list>:
the list from which the maximum element is to be found

B<returns>:
In scalar context: returns the first maximum element, or C<undef> if no elements are found.
In list context: returns the maximum elements, or the empty list of no elements are found. The maximum elements are returned in order.

= C<$scalar = _::min_by { BLOCK } @list>
= C<@list   = _::min_by { BLOCK } @list>
= C<$scalar = _::min_str_by { BLOCK } @list>
= C<@list   = _::min_str_by { BLOCK } @list>

See C<_::max_by> and C<_::max_str_by>.
These functions work equivalently, except that they return the minimum element(s).

=cut

# this function generates max_by, max_str_by, min_by, min_str_by
my $minmax_by = sub {
    my ($is_less_than) = @_;

    return sub (&@) {
        my $key_func = shift;

        return if not defined wantarray;  # nop in void context
        return if not @_;
        return $_[0] if not @_ > 1;

        if (wantarray) {
            my $max_key = do {
                local *_ = \$_[0];
                $key_func->();
            };
            my @max_elems = shift;
            for (@_) {
                my $key = $key_func->();
                next if $is_less_than->($key, $max_key);
                if ($is_less_than->($max_key, $key)) {
                    $max_key = $key;
                    @max_elems = ();
                }
                push @max_elems, $_;
            }
            return @max_elems;
        }
        else {
            my $max_elem = \shift;
            my $max_key = do {
                local *_ = $max_elem;
                $key_func->();
            };
            for (@_) {
                my $key = $key_func->();
                if ($is_less_than->($max_key, $key)) {
                    $max_key = $key;
                    $max_elem = \$_;
                }
            }
            return $$max_elem;
        }
    };
};

*max_by     = $minmax_by->(sub { $_[0] <  $_[1] });
*max_str_by = $minmax_by->(sub { $_[0] lt $_[1] });
*min_by     = $minmax_by->(sub { $_[1] <  $_[0] });
*min_str_by = $minmax_by->(sub { $_[1] lt $_[0] });

=pod

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

=C<@list = _::uniq_by { KEY } @list>

Discards duplicate values, using a key function to determine equality.
This can e.g. be used to deduplicate a set of objects, using the result of some method call to determine whether they're equivalent.

B<{ KEY }>:
The function to produce an equality key.
When called, the current element is passed in via the C<$_> variable.
This function must return a value that can be used as a hash key, i.e. a string.

B<@list>:
A list of values to deduplicate.

B<returns>:
A list containing the first value of each key.
In scalar context, returns the number of unique elements in the list.

=cut

sub uniq_by (&@) {
    my $key_func = shift;

    if (not defined wantarray) {
        Carp::carp "Useless use of _::uniq_by in void context";
        return;
    }

    if (@_ <= 1) {
        return @_ if wantarray;
        return 0+@_;
    }

    # caller context is propagated to grep, so this does the right thing.
    my %seen;
    grep { not $seen{ $key_func->() }++ } @_;
}

=pod

= C<%hash = _::classify { KEY } @list>

Categorizes the input items according to the provided key function.

The behavior in void context is undefined.

B<{ KEY }>:
A key function returning a category name.
The current item is passed in via C<$_>.
The return value must be usable as a hash key, i.e. be a string.

B<@list>:
The list of items to classify.

B<returns>:
A key-value-list of classified items, where each key is the category name, and each value is an array ref of items.
In scalar context, a hashref of arrayrefs is returned instead, which prevents unnecessary copies.

=cut

sub classify (&@) {
    my $key_func = shift;
    return if not @_;
    if (not defined wantarray) {
        Carp::carp "Useless use of _::classify in void context";
        return;
    }
    my %categories;
    push @{ $categories{ $key_func->() } }, $_ for @_;
    (wantarray) ? %categories : \%categories;
}

=pod

= C<@list = _::part { INDEX_FUNCTION } @list>
wrapper for C<List::MoreUtils::part>

= C<$iter = _::each_array \@array1, \@array2, ...>
wrapper for C<List::MoreUtils::each_arrayref>

=end :list

=cut

## no critic (ProtectPrivateVars)
$Util::Underscore::_ASSIGN_ALIASES->(
    'List::Util',
    reduce    => 'reduce',
    any       => 'any',
    all       => 'all',
    none      => 'none',
    max       => 'max',
    max_str   => 'maxstr',
    min       => 'min',
    min_str   => 'minstr',
    sum       => 'sum',
    product   => 'product',
    pairgrep  => 'pairgrep',
    pairfirst => 'pairfirst',
    pairmap   => 'pairmap',
    shuffle   => 'shuffle',
);

## no critic (ProtectPrivateVars)
$Util::Underscore::_ASSIGN_ALIASES->(
    'List::MoreUtils',
    first       => 'first_value',
    first_index => 'first_index',
    last        => 'last_value',
    last_index  => 'last_index',
    natatime    => 'natatime',
    uniq        => 'uniq',
    part        => 'part',
    each_array  => 'each_arrayref',
);

sub zip {
    goto &List::MoreUtils::zip;    # adios, prototypes!
}

1;
