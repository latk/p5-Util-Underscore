package Util::Underscore;
#ABSTRACT: Common helper functions without having to import them

use strict;
use warnings;
no warnings 'once';

use version 0.77 (); our $VERSION = version->declare('v1.0.1');

use Scalar::Util    1.36        ();
use List::Util      1.35        ();
use List::MoreUtils 0.07        ();
use Carp                        ();
use Safe::Isa       1.000000    ();
use Try::Tiny                   ();
use Data::Util      0.40        ();
use Package::Stash              ();
use Data::Dump                  ();

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
* L<Data::Util>
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

my $assign_aliases_simple = sub {
    my ($pkg, %aliases) = @_;
    no strict 'refs';  ## no critic ProhibitNoStrict
    while (my ($this, $that) = each %aliases) {
        *{'_::' . $this} =  *{$pkg . '::' . $that}{CODE}
                         // die "Unknown subroutine ${pkg}::${that}";
    }
};

my $assign_aliases = sub {
    my ($pkg, @aliases) = @_;
    die "aliases have wrong format" if not @aliases % 3 == 0;
    no strict 'refs';  ## no critic ProhibitNoStrict
    while (my ($copy, $orig, $proto) = splice @aliases, 0, 3) {
        my $orig_cv = *{"${pkg}::${orig}"}{CODE}
                    // die "Unknown subroutine ${pkg}::${orig}";
        my $copy_cv;
        if ($proto eq '/') {
             $copy_cv = $orig_cv;
        }
        else {
            $copy_cv = sub { goto &$orig_cv };
            Scalar::Util::set_prototype \&$copy_cv, $proto;
        }
        *{'_::' . $copy} = $copy_cv;
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

$assign_aliases_simple->('Scalar::Util' => qw{
    class           blessed
    blessed         blessed
    ref_addr        refaddr
    ref_type        reftype
    ref_weaken      weaken
    ref_unweaken    unweaken
    ref_is_weak     isweak
    new_dual        dualvar
    is_dual         isdual
    is_vstring      isvstring
    is_numeric      looks_like_number
    is_open         openhandle
    is_readonly     readonly
    is_tainted      tainted
});

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

=head2 Data::Util

=begin :list

= C<$bool = _::is_scalar_ref $scalar>
wrapper for C<Data::Util::is_scalar_ref>

= C<$bool = _::is_array_ref $scalar>
wrapper for C<Data::Util::is_array_ref>

= C<$bool = _::is_hash_ref $scalar>
wrapper for C<Data::Util::is_hash_ref>

= C<$bool = _::is_code_ref $scalar>
wrapper for C<Data::Util::is_code_ref>

= C<$bool = _::is_glob_ref $scalar>
wrapper for C<Data::Util::is_glob_ref>

= C<$bool = _::is_regex $scalar>
wrapper for C<Data::Util::is_rx>

= C<$bool = _::is_plain $scalar>
wrapper for C<Data::Util::is_value>

= C<$bool = _::is_int $scalar>
wrapper for C<Data::Util::is_integer>

=end :list

=cut

$assign_aliases->('Data::Util' => qw{
    is_scalar_ref   is_scalar_ref   _
    is_array_ref    is_array_ref    _
    is_hash_ref     is_hash_ref     _
    is_code_ref     is_code_ref     _
    is_glob_ref     is_glob_ref     _
    is_regex        is_rx           _
    is_plain        is_value        _
    is_int          is_integer      _
});

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

$assign_aliases_simple->('List::Util' => qw{
    reduce      reduce
    any         any
    all         all
    none        none
    max         max
    max_str     maxstr
    min         min
    min_str     minstr
    sum         sum
    product     product
    pairgrep    pairgrep
    pairfirst   pairfirst
    pairmap     pairmap
    shuffle     shuffle
});

$assign_aliases_simple->('List::MoreUtils' => qw{
    first       first_value
    first_index first_index
    last        last_value
    last_index  last_index
    natatime    natatime
    uniq        uniq
    part        part
    each_array  each_arrayref
});

sub _::zip {
    goto &List::MoreUtils::zip;  # adios, prototypes!
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

$assign_aliases_simple->('Carp' => qw{
    carp    carp
    cluck   cluck
    croak   croak
    confess confess
});

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

sub _::isa($$) {  ## no critic ProhibitSubroutinePrototypes
    goto &$Safe::Isa::_isa;
}

sub _::does($$) {  ## no critic ProhibitSubroutinePrototypes
    goto &$Safe::Isa::_DOES;
}

sub _::can($$) {  ## no critic ProhibitSubroutinePrototypes
    goto &$Safe::Isa::_can;
}

sub _::safecall($$@) {  ## no critic ProhibitSubroutinePrototypes
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

$assign_aliases_simple->('Try::Tiny' => qw{
    try     try
    catch   catch
    finally finally
});

=head2 Package::Stash

The C<_::package $str> function will return a new C<Package::Stash> instance.

=cut

sub _::package($) { ## no critic ProhibitSubroutinePrototypes
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

= C<$str = _::quote $str>
wrapper for C<Data::Dump::quote>.

=cut

$assign_aliases->('Data::Dump' => qw{
    pp      pp      /
    dd      dd      /
    quote   quote   _
});

1;
