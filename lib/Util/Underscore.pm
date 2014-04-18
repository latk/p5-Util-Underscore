package Util::Underscore;

#ABSTRACT: Common helper functions without having to import them

use strict;
use warnings;
no warnings 'once';

use version 0.77 (); our $VERSION = version->declare('v1.0.1');

use Scalar::Util 1.36    ();
use List::Util 1.35      ();
use List::MoreUtils 0.07 ();
use Carp       ();
use Try::Tiny  ();
use Data::Dump ();
use overload   ();

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

# From now, every function is in the _ package
package    # Hide from PAUSE
    _;

my $assign_aliases;

BEGIN {
    $assign_aliases = sub {
        my ($pkg, %aliases) = @_;
        no strict 'refs';    ## no critic ProhibitNoStrict
        while (my ($this, $that) = each %aliases) {
            *{ '_::' . $this } = *{ $pkg . '::' . $that }{CODE}
                // die "Unknown subroutine ${pkg}::${that}";
        }
    };

    # Inject immediately during compile because we want to use unprefixed subs
    # in our other subs definitions below.
    $assign_aliases->(
        'Scalar::Util',
        ref_addr     => 'refaddr',
        ref_type     => 'reftype',
        ref_weaken   => 'weaken',
        ref_unweaken => 'unweaken',
        ref_is_weak  => 'isweak',
        new_dual     => 'dualvar',
        is_numeric   => 'looks_like_number',
        is_open      => 'openhandle',
    );
}

sub blessed(_) {
    goto &Scalar::Util::blessed;
}

{
    no warnings 'once';
    *class = \&blessed;
}

=head2 Scalars

These functions are about manipulating scalars.

=begin :list

= C<$scalar = _::new_dual $num, $str>

wrapper for C<Scalar::Util::dualvar>

= C<$bool = _::is_dual $scalar>

wrapper for C<Scalar::Util::isdual>

= C<$bool = _::is_vstring $scalar>

wrapper for C<Scalar::Util::isvstring>

= C<$bool = _::is_readonly $scalar>

wrapper for C<Scalar::Util::readonly>

= C<$bool = _::is_tainted $scalar>

wrapper for C<Scalar::Util::tainted>

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

=end :list

=cut

sub is_dual(_) {
    goto &Scalar::Util::isdual;
}

sub is_vstring(_) {
    goto &Scalar::Util::isvstring;
}

sub is_readonly(_) {
    goto &Scalar::Util::readonly;
}

sub is_tainted (_) {
    goto &Scalar::Util::tainted;
}

sub is_plain(_) {
    defined $_[0]
        && !defined ref_type $_[0];
}

sub is_identifier(_) {
    defined $_[0]
        && scalar($_[0] =~ /\A [^\W\d]\w* \z/x);
}

sub is_package(_) {
    defined $_[0]
        && scalar($_[0] =~ /\A [^\W\d]\w* (?: [:][:]\w+ )* \z/x);
}

=head2 Numbers

=begin :list

= C<$bool = _::is_numeric $scalar>

wrapper for C<Scalar::Util::looks_like_number>

= C<$bool = _::is_int $_>

The argument is a plain scalar,
and its stringification matches a signed integer.

= C<$bool = _::is_uint $_>

Like C<_::is_int>, but the stringification must match an unsigned integer
(i.e. the number is zero or positive).

=end :list

=cut

sub is_int(_) {
    defined $_[0]
        && !defined ref_type $_[0]
        && scalar($_[0] =~ /\A [-]? [0-9]+ \z/x);
}

sub is_uint(_) {
    defined $_[0]
        && !defined ref_type $_[0]
        && scalar($_[0] =~ /\A [0-9]+ \z/x);
}

=head2 References

=begin :list

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

=end :list

=head3 Type Validation

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

sub is_ref(_) {
    defined($_[0])
        && defined ref_type $_[0]
        && !defined blessed $_[0];
}

sub is_scalar_ref(_) {
    defined($_[0])
        && ('SCALAR' eq ref $_[0]
        || overload::Method($_[0], '${}'));
}

sub is_array_ref(_) {
    defined($_[0])
        && ('ARRAY' eq ref $_[0]
        || overload::Method($_[0], '@{}'));
}

sub is_hash_ref(_) {
    defined($_[0])
        && ('HASH' eq ref $_[0]
        || overload::Method($_[0], '%{}'));
}

sub is_code_ref(_) {
    defined($_[0])
        && ('CODE' eq ref $_[0]
        || overload::Method($_[0], '&{}'));
}

sub is_glob_ref(_) {
    defined($_[0])
        && ('GLOB' eq ref $_[0]
        || overload::Method($_[0], '*{}'));
}

sub is_regex(_) {
    defined(blessed $_[0])
        && ('Regexp' eq ref $_[0]
        || overload::Method($_[0], 'qr'));
}

=head2 Classes and Objects

=begin :list

= C<$str = _::blessed $object>
= C<$str = _::class $object>

wrapper for C<Scalar::Util::blessed>

= C<$bool = _::is_object $_>

Checks that the argument is a blessed object.
It's just an abbreviation for C<defined _::blessed $_>

= C<$bool = _::class_isa $class, $supertype>

Checks that the C<$class> inherits from the given C<$supertype>, both given as strings.
In most cases, one should use C<_::class_does> instead.

= C<$bool = _::class_does $class, $role>

Checks that the C<$class> performs the given C<$role>, both given as strings.

= C<$bool = _::is_instance $object, $role>

Checks that the given C<$object> can perform the C<$role>.
This is essentially equivalent to `_::does`.

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

sub is_object(_) {
    defined blessed $_[0];
}

sub class_isa($$) {
    is_package($_[0])
        && $_[0]->isa($_[1]);
}

sub class_does($$) {
    is_package($_[0])
        && $_[0]->DOES($_[1]);
}

sub is_instance($$) {
    blessed $_[0]
        && $_[0]->DOES($_[1]);
}

sub class_can($$) {
    is_package($_[0])
        && $_[0]->can($_[1]);
}

sub isa($$) {
    blessed $_[0]
        && $_[0]->isa($_[1]);
}

sub does($$) {
    blessed $_[0]
        && $_[0]->DOES($_[1]);
}

sub can($$) {
    blessed $_[0]
        && $_[0]->can($_[1]);
}

sub safecall($$@) {
    my $self = shift;
    my $meth = shift;
    return unless blessed $self;
    $self->$meth(@_);
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

sub zip {
    goto &List::MoreUtils::zip;    # adios, prototypes!
}

=head2 Exception handling

The functions C<_::carp>, C<_::cluck>, C<_::croak>, and C<_::confess> from the C<Carp> module are available.
They all take a list of strings as argument.
How do they differ from each other?

    Stack Trace || Fatal    | Warning
    ------------##====================
        No      || croak    | carp
        Yes     || confess  | cluck

How do they differ from Perl's builtin C<die> and C<warn>?
The error messages of C<die> and C<warn> are located on the line where the exception is raised.
This makes debugging hard when the error points to some internal function of a module you are using,
as this provides no information on where your client code made a mistake.
The C<Carp> family of error functions report the error from the point of usage, and optionally provide stack traces.
If you write a module, please use the C<Carp> functions instead of plain C<die>.

Additionally, the variants C<_::carpf>, C<_::cluckf>, C<_::croakf>, and C<_::confessf> are provided.
These take a C<sprintf> patterns as first argument: C<_::carpf "pattern", @arguments>.

To handle errors, the following keywords from C<Try::Tiny> are available:

=for :list
* C<_::try>
* C<_::catch>
* C<_::finally>

They are all direct aliases for their namesakes in C<Try::Tiny>.

=cut

BEGIN {
    $assign_aliases->(
        'Carp',
        carp    => 'carp',
        cluck   => 'cluck',
        croak   => 'croak',
        confess => 'confess',
    );
}

$assign_aliases->(
    'Try::Tiny',
    try     => 'try',
    catch   => 'catch',
    finally => 'finally',
);

sub carpf($@) {
    my $pattern = shift;
    @_ = sprintf $pattern, @_;
    goto &carp;
}

sub cluckf($@) {
    my $pattern = shift;
    @_ = sprintf $pattern, @_;
    goto &cluck;
}

sub croakf($@) {
    my $pattern = shift;
    @_ = sprintf $pattern, @_;
    goto &croak;
}

sub confessf($@) {
    my $pattern = shift;
    @_ = sprintf $pattern, @_;
    goto &confess;
}

=head2 Miscellaneous Functions

=begin :list

= C<$fh = _::is_open $fh>

wrapper for C<Scalar::Util::openhandle>

= C<$str = _::prototype \&code>
= C<_::prototype \&code, $new_proto>

gets or sets the prototype, wrapping either C<CORE::prototype> or C<Scalar::Util::set_prototype>

= C<$instance = _::package $str>

This will construct a new C<Package::Stash> instance.

=end :list

C<Data::Dump> is an alternative to C<Data::Dumper>.
The main difference is the output format: C<Data::Dump> output tends to be easier to read.

=begin :list

= C<$str = _::pp @values>
wrapper for C<Data::Dump::pp>

= C<_::dd @values>
wrapper for C<Data::Dump::dd>.

=end :list

=cut

sub _::prototype ($;$) {
    if (@_ == 2) {
        goto &Scalar::Util::set_prototype if @_ == 2;
    }
    if (@_ == 1) {
        my ($coderef) = @_;
        return prototype $coderef;    # Calls CORE::prototype
    }
    else {
        Carp::confess '_::prototype(&;$) takes exactly one or two arguments';
    }
}

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
* L<Safe::Isa>

=cut

1;
