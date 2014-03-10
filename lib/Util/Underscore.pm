package Util::Underscore;

#ABSTRACT: Common helper functions without having to import them

use strict;
use warnings;
no warnings 'once';

use version 0.77 (); our $VERSION = version->declare('v1.0.1');

use Scalar::Util 1.36    ();
use List::Util 1.35      ();
use List::MoreUtils 0.07 ();
use Carp ();
use Safe::Isa 1.000000 ();
use Try::Tiny      ();
use Package::Stash ();
use Data::Dump     ();
use overload       ();

use constant {
    true  => !!1,
    false => !!0,
};

## no critic ProhibitSubroutinePrototypes

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

my $assign_aliases = sub {
    my ($pkg, %aliases) = @_;
    no strict 'refs';    ## no critic ProhibitNoStrict
    while (my ($this, $that) = each %aliases) {
        *{ '_::' . $this } = *{ $pkg . '::' . $that }{CODE}
            // die "Unknown subroutine ${pkg}::${that}";
    }
};

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

$assign_aliases->(
    'Scalar::Util',
    class        => 'blessed',
    blessed      => 'blessed',
    ref_addr     => 'refaddr',
    ref_type     => 'reftype',
    ref_weaken   => 'weaken',
    ref_unweaken => 'unweaken',
    ref_is_weak  => 'isweak',
    new_dual     => 'dualvar',
    is_dual      => 'isdual',
    is_vstring   => 'isvstring',
    is_numeric   => 'looks_like_number',
    is_open      => 'openhandle',
    is_readonly  => 'readonly',
    is_tainted   => 'tainted',
);

sub _::prototype ($;$) {
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

=head2 Type Validation Utils

These are inspired from C<Params::Util> and C<Data::Util>.

The I<reference validation> routines take one argument (or C<$_>) and return a boolean value.
They return true when the value is intended to be used as a reference of that kind:
either C<ref $arg> is of the requested type,
or it is an overloaded object that can be used as a reference of that kind.
It will not be checked that an object claims to perform an appropriate role (e.g. C<< $arg->DOES('ARRAY') >>).

=for :list
* C<_::is_ref> (any nonblessed reference)
* C<_::is_scalar_ref>
* C<_::is_array_ref>
* C<_::is_hash_ref>
* C<_::is_code_ref>
* C<_::is_glob_ref>
* C<_::is_regex> (note that regexes are blessed objects, not plain references)

=cut

sub _::is_ref(_) {
    return false if not defined $_[0];
    return true
        if defined Scalar::Util::reftype $_[0]
        && !defined Scalar::Util::blessed $_[0];
    return false;
}

sub _::is_scalar_ref(_) {
    return false if not defined $_[0];
    return true
        if 'SCALAR' eq ref $_[0]
        || overload::Method($_[0], '${}');
    return false;
}

sub _::is_array_ref(_) {
    return false if not defined $_[0];
    return true
        if 'ARRAY' eq ref $_[0]
        || overload::Method($_[0], '@{}');
    return false;
}

sub _::is_hash_ref(_) {
    return false if not defined $_[0];
    return true
        if 'HASH' eq ref $_[0]
        || overload::Method($_[0], '%{}');
    return false;
}

sub _::is_code_ref(_) {
    return false if not defined $_[0];
    return true
        if 'CODE' eq ref $_[0]
        || overload::Method($_[0], '&{}');
    return false;
}

sub _::is_glob_ref(_) {
    return false if not defined $_[0];
    return true
        if 'GLOB' eq ref $_[0]
        || overload::Method($_[0], '*{}');
    return false;
}

sub _::is_regex(_) {
    return false if not defined Scalar::Util::blessed $_[0];
    return true
        if 'Regexp' eq ref $_[0]
        || overload::Method($_[0], 'qr');
    return false;
}

=pod

An assortment of other validation routines remains.
A I<simple scalar> is a scalar value which is neither C<undef> nor a reference.

=begin :list

= C<$bool = _::is_int $_>

The argument is a simple scalar that's neither C<undef> nor a reference,
and its stringification matches a signed integer.

= C<$bool = _::is_uint $_>

Like C<_::is_int>, but the stringification must match an unsigned integer
(i.e. the number is zero or positive).

= C<$bool = _::is_plain $_>

Checks that the value is C<defined> and not a reference of any kind.
This is as close as Perl gets to checking for a string.

= C<$bool = _::is_identifier $_>

Checks that the given string would be a legal identifier:
a letter followed by zero or more word characters.

= C<$bool = _::is_package $_>

Checks that the given string is a valid package name.
It only accepts C<Foo::Bar> notation, not the C<Foo'Bar> form.
This does not assert that the package actually exists.

= C<$bool = _::class_isa $class, $supertype>

Checks that the C<$class> inherits from the given C<$supertype>, both given as strings.
In most cases, one should use `_::class_does` instead.

= C<$bool = _::class_does $class, $role>

Checks that the C<$class> performs the given C<$role>, both given as strings.

= C<$bool = _::is_instance $object, $role>

Checks that the given C<$object> can perform the C<$role>.
This is essentially equivalent to `_::does`.

=end :list

=cut

sub _::is_int(_) {
    return true
        if defined $_[0]
        && !defined Scalar::Util::reftype $_[0]
        && $_[0] =~ /\A [-]? [0-9]+ \z/x;
    return false;
}

sub _::is_uint(_) {
    return true
        if defined $_[0]
        && !defined Scalar::Util::reftype $_[0]
        && $_[0] =~ /\A [0-9]+ \z/x;
    return false;
}

sub _::is_plain(_) {
    return true
        if defined $_[0]
        && !defined Scalar::Util::reftype $_[0];
    return false;
}

sub _::is_identifier(_) {
    return true
        if defined $_[0]
        && $_[0] =~ /\A [^\W\d]\w* \z/x;
    return false;
}

sub _::is_package(_) {
    return true
        if defined $_[0]
        && $_[0] =~ /\A [^\W\d]\w* (?: [:][:]\w+ )* \z/x;
    return false;
}

sub _::class_isa($$) {
    return true
        if _::is_package $_[0]
        && $_[0]->isa($_[1]);
    return false;
}

sub _::class_does($$) {
    return true
        if _::is_package $_[0]
        && $_[0]->DOES($_[1]);
    return false;
}

sub _::is_instance($$) {
    return true
        if Scalar::Util::blessed $_[0]
        && $_[0]->DOES($_[1]);
    return false;
}

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

$assign_aliases->(
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

$assign_aliases->(
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

sub _::zip {
    goto &List::MoreUtils::zip;    # adios, prototypes!
}

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

$assign_aliases->(
    'Carp',
    carp    => 'carp',
    cluck   => 'cluck',
    croak   => 'croak',
    confess => 'confess',
);

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

sub _::isa($$) {
    goto &$Safe::Isa::_isa;
}

sub _::does($$) {
    goto &$Safe::Isa::_DOES;
}

sub _::can($$) {
    goto &$Safe::Isa::_can;
}

sub _::safecall($$@) {
    goto &$Safe::Isa::_call_if_object;
}

=head2 Try::Tiny

The following keywords are available:

=for :list
* C<_::try>
* C<_::catch>
* C<_::finally>

They are all direct aliases for their namesakes in C<Try::Tiny>.

=cut

$assign_aliases->(
    'Try::Tiny',
    try     => 'try',
    catch   => 'catch',
    finally => 'finally',
);

=head2 Package::Stash

The C<_::package $str> function will return a new C<Package::Stash> instance.

=cut

sub _::package($) {
    my ($pkg) = @_;
    return Package::Stash->new($pkg);
}

=head2 Data::Dump

C<Data::Dump> is an alternative to C<Data::Dumper>.
The main difference is the output format: C<Data::Dump> output tends to be easier to read.

=begin :list

= C<$str = _::pp @values>
wrapper for C<Data::Dump::pp>

= C<_::dd @values>
wrapper for C<Data::Dump::dd>.

=end :list

=cut

$assign_aliases->(
    'Data::Dump',
    pp => 'pp',
    dd => 'dd',
);

=head1 RELATED MODULES

The following modules were once considered for inclusion or were otherwise influental in the design of this collection:

=for :list
* L<Data::Util>
* L<Params::Util>

=cut

1;
