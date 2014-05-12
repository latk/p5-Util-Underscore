package Util::Underscore;

#ABSTRACT: Common helper functions without having to import them
#CONTRIBUTOR: Lukas Atkinson (cpan: AMON) <amon@cpan.org>
#CONTRIBUTOR: Olivier Mengué (cpan: DOLMEN) <dolmen@cpan.org>

use strict;
use warnings;

use version 0.77; our $VERSION = qv('v1.1.1');
use overload ();

use Carp ();
use Const::Fast 0.011    ();
use Data::Alias 1.18     ();
use Data::Dump 1.10      ();
use List::MoreUtils 0.07 ();
use List::Util 1.35      ();
use POSIX ();
use Scalar::Util 1.36 ();
use Try::Tiny 0.03    ();

=pod

=encoding utf8

=head1 SYNOPSIS

    use Util::Underscore;
    
    _::croak "$foo must do Some::Role" if not _::does($foo, 'Some::Role');
    

=head1 DESCRIPTION

This module contains various utility functions, and makes them accessible through the C<_> package.
This allows the use of these utilities (a) without much per-usage overhead and (b) without namespace pollution.

It contains selected functions from the following modules:
L<Carp|Carp>,
L<Const::Fast|Const::Fast>,
L<Data::Alias|Data::Alias>,
L<Data::Dump|Data::Dump>,
L<List::MoreUtils|List::MoreUtils>,
L<List::Util|List::Util>,
L<POSIX|POSIX>,
L<Scalar::Util|Scalar::Util>,
L<Try::Tiny|Try::Tiny>.

Not all functions from those are available, some have been renamed, and some functions of our own have been added.

=cut

BEGIN {
    # check if a competing "_" exists
    if (keys %{_::}) {
        Carp::confess qq(The package "_" has already been defined);
    }
}

BEGIN {
    # Load the dummy "_.pm" module.
    # This will set up various booby traps so that "_" isn't used directly.
    # In order to prevent the traps from triggering when *we* go there, we have
    # to declare our peaceful intentions:
    local our $_WE_COME_IN_PEACE = 'pinky swear';
    require _;
}

my $assign_aliases;

BEGIN {
    $assign_aliases = sub {
        my ($pkg, %aliases) = @_;
        no strict 'refs';    ## no critic (ProhibitNoStrict)
        while (my ($this, $that) = each %aliases) {
            my $target = "_::${this}";
            my $source = "${pkg}::${that}";
            *{$target} = *{$source}{CODE}
                // Carp::croak "Unknown subroutine $source in assign_aliases";
        }
    };
}

=head1 FUNCTION REFERENCE

=cut

# From now, every function is in the "_" package
## no critic (ProhibitMultiplePackages)
package    # Hide from PAUSE
    _;

## no critic (RequireArgUnpacking, RequireFinalReturn, ProhibitSubroutinePrototypes)
#   Why this "no critic"? In an util module, efficiency is crucial because we
# have no idea about the context where these function are being used. Therefore,
# no arg unpacking, and no explicit return. Most functions are so trivial anyway
# that this isn't much of a legibility concern.
#   Subroutine prototypes are used to offer a convenient and natural interface.
# I fully understand why they shouldn't be used in ordinary code, but this
# module puts them to mostly good use.

# Predeclare a few things so that we can use them in the sub definitions below.
sub blessed(_);
sub ref_type(_);

=head2 Scalars

These functions are about manipulating scalars.

=begin :list

= C<$scalar = _::new_dual $num, $str>

Creates a new dualvar with numeric value C<$num> and string value C<$str>.

In Perl, scalars contain both a numeric value and a string value.
Usually, Perl freely converts between the two values.
A dualvar disables the syncing between the two values, so that the string value and the numeric value can be completely unrelated.

wrapper for C<Scalar::Util::dualvar>

B<$num>:
the value for the numeric slot

B<$str>:
the value for the string slot

B<returns>:
a new dualvar

= C<$bool = _::is_dual $scalar>
= C<$bool = _::is_dual>

Checks whether the given scalar is a dualvar.

wrapper for C<Scalar::Util::isdual>

B<$scalar>:
the scalar to check. If omitted, uses C<$_>.

B<returns>:
a boolean value indicating whether the C<$scalar> is a dualvar.

= C<$bool = _::is_vstring $scalar>
= C<$bool = _::is_vstring>

Checks whether the given C<$scalar> was created as a v-string like C<v127.0.0.1> or C<v1.0.3>.

wrapper for C<Scalar::Util::isvstring>

B<$scalar>:
the scalar to check.
If omitted, uses C<$_>.

B<returns>:
a boolean value indicating whether the C<$scalar> is a v-string.

= C<< _::const LVALUE => VALUE >>

Creates a readonly variable containing the specified value.

Note that this makes a deep immutable copy of the value instead of only disallowing reassignment.
This works for scalars, arrays, and hashes.
Certain care has to be taken for hashes because this locks the keys,
and using an illegal key would blow up with an error.
Therefore: always use S<C<exists $hash{$key}>> to see whether a key exists.

Examples:

    _::const my $const => 42;
    _::const my @const => 1, 2, 3;
    _::const my %const => a => 1, b => 2;

Wrapper for C<const> from L<Const::Fast|Const::Fast>.

B<LVALUE>:
an lvalue (scalar, hash, or array variable) to make constant.

B<VALUE>:
the value to make deeply immutable and assign.
The expression is always evaluated in list context, but the length of the resulting list must match the lvalue type.

B<returns>:
n/a

= C<$bool = _::is_readonly $scalar>
= C<$bool = _::is_readonly>

Checks whether the given scalar is readonly, i.e. can't be reassigned.

wrapper for C<Scalar::Util::readonly>

B<$scalar>:
the scalar to check for readonlyness.
If omitted, uses C<$_>.

B<returns>:
a boolean indicating whether the C<$scalar> is readonly.

= C<$bool = _::is_tainted $scalar>
= C<$bool = _::is_tainted>

Checks whether the C<$scalar> is tainted.

Tainted values come from untrusted sources, such as user input, environment variables, or file contents.
The result of a computation with tainted values is itself tainted.
Tainting is only traced when requested via the C<-t> or C<-T> command line switch.
If activated, certain builtins will refuse to execute with tainted input, such as C<open> or C<system>.
See L<perlsec|perlsec/"Taint mode"> for more information.

wrapper for C<Scalar::Util::tainted>

B<$scalar>:
the scalar to check for taintedness.
If omitted, uses C<$_>.

B<returns>:
a boolean indicating whether the C<$scalar> is tainted.

= C<_::alias my $alias = $orig>

Aliases the first variable to the second scalar, unlike normal assignment which assigns a copy.

Afterwards, the C<$alias> will be another name for the C<$orig> scalar, so C<\$alias == \$orig> will always be true.
As the same scalar is now accessible by two names, changes are also visible under the other name.

Aliases occur naturally with the C<for>, C<map>, and C<grep> builtins:

    my @values = qw(a b c);
    for (@values) {
        # now $_ is an alias for the current element
        $_ = 42;
    }
    # @values = (42, 42, 42)

but also with subroutine parameters:

    sub assign {
        # the values in @_ are aliases for the arguments
        $_[0] = $_[1];
        return;
    }

    my $x = "foo";
    assign $x => "bar";
    # $x = "bar"

This function is an alias (heh) for the functionality in L<Data::Alias|Data::Alias>.

B<$alias>:
an additional name for the C<$orig> scalar.

B<$orig>:
The alias target.

B<returns>:
n/a

= C<$bool = _::is_plain $scalar>
= C<$bool = _::is_plain>

Checks that the value is C<defined> and not a reference of any kind.

This is as close as Perl gets to checking for an ordinary string.

B<$scalar>:
the scalar to check.
If omitted, uses C<$_>.

B<returns>:
a boolean indicating whether the scalar is plain.

= C<$bool = _::is_string $scalar>
= C<$bool = _::is_string>

Checks that the value is intended to be usable as a string:
Either C<_::is_plain> returns true, or it is an object that has overloaded stringification.

This does not test that the scalar has ever been used as a string, or was assigned as a string, only that it I<can> be used as a string.
Note that some data structures (like references) do have a stringification, but this is rarely intended to be actually used and therefore rejected.

B<$scalar>:
the scalar to check for stringiness.

B<returns>:
a boolean indicating whether the scalar is string-like.

= C<$bool = _::is_identifier $string>
= C<$bool = _::is_identifier $>

Checks that the given string would be a legal identifier:
a letter followed by zero or more word characters.

B<$string>:
a string possibly containing an identifier.

B<returns>:
a boolean indicating whether the string looks like an identifier.

= C<$bool = _::is_package $string>
= C<$bool = _::is_package>

Checks that the given string is a valid package name.
It only accepts C<Foo::Bar> notation, not the C<Foo'Bar> form.
This does not assert that the package actually exists.

B<$string>:
a string possibly containing a package name.

B<returns>:
a boolean indicating whether the given string looks like a package name.

=end :list

=cut

$assign_aliases->('Scalar::Util', new_dual => 'dualvar');

sub is_dual(_) {
    goto &Scalar::Util::isdual;
}

sub is_vstring(_) {
    goto &Scalar::Util::isvstring;
}

sub is_readonly(_) {
    goto &Scalar::Util::readonly;
}

$assign_aliases->('Const::Fast', const => 'const');

sub is_tainted (_) {
    goto &Scalar::Util::tainted;
}

$assign_aliases->('Data::Alias', alias => 'alias');

sub is_plain(_) {
    defined $_[0]
        && !defined ref_type $_[0];
}

sub is_string(_) {
    defined $_[0]
        && (!defined ref_type $_[0]
        || overload::Method($_[0], q[""]));
}

sub is_identifier(_) {
    defined $_[0]
        && scalar($_[0] =~ /\A [^\W\d]\w* \z/xsm);
}

sub is_package(_) {
    defined $_[0]
        && scalar($_[0] =~ /\A [^\W\d]\w* (?: [:][:]\w+ )* \z/xsm);
}

=head2 Numbers

=begin :list

= C<$bool = _::is_numeric $scalar>
= C<$bool = _::is_numeric>

Check whether Perl considers the C<$scalar> to be numeric in any way.

This includes integers and various floating point formats, but usually also C<NaN> and C<inf> and some other special strings.

wrapper for C<Scalar::Util::looks_like_number>

B<$scalar>:
the scalar to check for numericness.
If omitted, uses C<$_>.

B<returns>:
a boolean value indicating whether the C<$scalar> can be used as a numeric value.

= C<$bool = _::is_int $scalar>
= C<$bool = _::is_int>

Checks that the argument is a plain scalar,
and its stringification matches a signed integer.

B<$scalar>:
the scalar to be checked.
If omitted, uses C<$_>.

B<returns>:
a boolean value indicating whether the C<$scalar> is an integer.

= C<$bool = _::is_uint $scalar>
= C<$bool = _::is_uint>

Like C<_::is_int>, but the stringification must match an unsigned integer
(i.e. the number is zero or positive).

B<$scalar>:
the scalar to be checked.
If omitted, uses C<$_>.

B<returns>:
a boolean value indicating whether the C<$scalar> is an unsigned integer.

= C<$int = _::ceil $float>
= C<$int = _::ceil>

wrapper for C<POSIX::ceil>

B<$float>:
any number.
If omitted, uses C<$_>.

B<returns>:
a float representing the smallest integral value greater than or equal to the C<$float>.
If the C<$float> is not a finite number (i.e. infinite or NaN), then that input is returned.

= C<$int = _::floor $float>
= C<$int = _::floor>

wrapper for C<POSIX::floor>

This is different from the C<int()> builtin in that C<int()> I<truncates> a float towards zero,
and that C<int()> actually returns an integer.

B<$float>:
any number.
If omitted, uses C<$_>.

B<returns>:
a float representing the smallest integral value smaller than or equal to the argument.
If the C<$float> is not a finite number (i.e. infinite or NaN), then that input is returned.

=end :list

=cut

sub is_numeric(_) {
    goto &Scalar::Util::looks_like_number;
}

sub is_int(_) {
    ## no critic (ProhibitEnumeratedClasses)
    defined $_[0]
        && !defined ref_type $_[0]
        && scalar($_[0] =~ /\A [-]? [0-9]+ \z/xsm);
}

sub is_uint(_) {
    ## no critic (ProhibitEnumeratedClasses)
    defined $_[0]
        && !defined ref_type $_[0]
        && scalar($_[0] =~ /\A [0-9]+ \z/xsm);
}

sub ceil(_) {
    goto &POSIX::ceil;
}

sub floor(_) {
    goto &POSIX::floor;
}

=head2 References

=begin :list

= C<$int = _::ref_addr $reference>
= C<$int = _::ref_addr>

wrapper for C<Scalar::Util::refaddr>

This is mostly equivalent to the numification of a reference: C<0+$ref>.
However, that fails for objects which have overloaded addition, which is why you should use this function instead.

The ref address denotes identity:
two references with the same address are the same object.
However, the same address might be reused later, so storing the address is not useful.
Use weak references instead.

B<$reference>:
the reference to obtain the address of.
If omitted, uses C<$_>.

B<returns>:
an integer representing ther reference address if the input is any kind of reference (plain reference or object).
If the input is not a reference, C<undef> is returned.

= C<$str = _::ref_type $reference>
= C<$str = _::ref_type>

wrapper for C<Scalar::Util::reftype>

Accesses the type of the bare reference:
C<SCALAR>, C<REF>, C<ARRAY>, C<HASH>, C<CODE>, C<GLOB>, C<REGEXP>.
Unfortunately, regexes are special, so C<_::ref_type qr//> is C<REGEXP> while C<ref qr//> is C<Regexp>.

B<$reference>:
the reference to obtain the type of.
If omitted, uses C<$_>.

B<returns>:
the type of the reference.
For blessed references, this will not be the class, but the type of the blessed reference.
If the input is not a reference, C<undef> is returned.

= C<_::ref_weaken $reference>
= C<_::ref_weaken>

Turns the reference into a weak reference.

wrapper for C<Scalar::Util::weaken>

B<$reference>:
the reference to weaken.
If omitted, uses C<$_>.

B<returns>:
n/a

= C<_::ref_unweaken $reference>
= C<_::ref_unweaken>

Turns a weak reference into a normal reference.

wrapper for C<Scalar::Util::unweaken>

B<$reference>:
the reference to unweaken.
If omitted, uses C<$_>.

B<returns>:
n/a

= C<$bool = _::ref_is_weak $reference>
= C<$bool = _::ref_is_weak>

Checks whether the given reference is a weak reference.

wrapper for C<Scalar::Util::isweak>

B<$reference>:
the reference to check.
If omitted, uses C<$_>.

B<returns>:
a boolean indicating whether the given C<$reference> was a weak reference.

=end :list

=head3 Type Validation

These are inspired from C<Params::Util> and C<Data::Util>.

The I<reference validation> routines take one argument (or C<$_>) and return a boolean value.
They return true when the value is intended to be used as a reference of that kind:
either C<ref_type $arg> is of the requested type,
or it is an overloaded object that can be used as a reference of that kind.
It will not be checked that an object claims to perform an appropriate role (e.g. C<< $arg->DOES('ARRAY') >>).

=for :list
* C<_::is_ref> (any nonblessed reference)
* C<_::is_scalar_ref> (also references to references)
* C<_::is_array_ref>
* C<_::is_hash_ref>
* C<_::is_code_ref>
* C<_::is_glob_ref>
* C<_::is_regex> (note that regexes are blessed objects, not plain references)

=cut

sub ref_addr(_) {
    goto &Scalar::Util::refaddr;
}

sub ref_type(_) {
    goto &Scalar::Util::reftype;
}

sub ref_weaken(_) {
    goto &Scalar::Util::weaken;
}

sub ref_unweaken(_) {
    goto &Scalar::Util::unweaken;
}

sub ref_is_weak(_) {
    goto &Scalar::Util::isweak;
}

sub is_ref(_) {
    defined($_[0])
        && defined ref_type $_[0]
        && !defined blessed $_[0];
}

sub is_scalar_ref(_) {
    defined($_[0])
        && (
        (defined blessed $_[0])
        ? overload::Method($_[0], q[${}])
        : do {
            my $type = ref_type $_[0] // q[];
            $type eq 'SCALAR' || $type eq 'REF';
        }
        );
}

sub is_array_ref(_) {
    defined($_[0])
        && (
        (defined blessed $_[0])
        ? overload::Method($_[0], q[@{}])
        : (ref_type $_[0] // q[]) eq 'ARRAY'
        );
}

sub is_hash_ref(_) {
    defined($_[0])
        && (
        (defined blessed $_[0])
        ? overload::Method($_[0], q[%{}])
        : (ref_type $_[0] // q[]) eq 'HASH'
        );
}

sub is_code_ref(_) {
    defined($_[0])
        && (
        (defined blessed $_[0])
        ? overload::Method($_[0], q[&{}])
        : (ref_type $_[0] // q[]) eq 'CODE'
        );
}

sub is_glob_ref(_) {
    defined($_[0])
        && (
        (defined blessed $_[0])
        ? overload::Method($_[0], q[*{}])
        : (ref_type $_[0] // q[]) eq 'GLOB'
        );
}

sub is_regex(_) {
    defined(blessed $_[0])
        && ('REGEXP' eq ref_type $_[0]
        || overload::Method($_[0], q[qr]));
}

=head2 Classes and Objects

=begin :list

= C<$str = _::blessed $obj>
= C<$str = _::blessed>
= C<$str = _::class $obj>
= C<$str = _::class>

Accesses the class of the provided object.

Wrapper for C<Scalar::Util::blessed>.

B<$obj>:
the object of which the class is to be determined.
If omitted, uses C<$_>.

B<returns>:
The class of C<$obj> if that is a blessed scalar, else returns C<undef>.

= C<$bool = _::is_object $scalar>
= C<$bool = _::is_object>

Checks that the argument is a blessed object.
It's just an abbreviation for C<defined _::blessed $scalar>.

B<$scalar>:
the scalar which may or may not be a blessed object.

B<returns>:
a boolean indicating whether the C<$scalar> is a blessed object.

= C<$bool = _::class_isa $class, $supertype>

Checks that the C<$class> inherits from the given C<$supertype>, both given as strings.
In most cases, one should use C<_::class_does> instead.

B<$class>:
the name of the class.

B<$supertype>:
the name of another class.

B<returns>:
a boolean indicating whether C<$class> inherits from C<$supertype>.

= C<$bool = _::class_does $class, $role>

Checks that the C<$class> performs the given C<$role>, both given as strings.
This means that the C<$class> has a compatible interface to the C<$role>.
However, this does not require that the C<$class> inherits from the C<$role>.

B<$class>:
the name of the class.

B<$role>:
the name of a role.

B<returns>:
a boolean indicating whether C<$class> conforms to the C<$role>.

= C<$bool = _::isa $object, $class>

Checks that the C<$object> inherits from the given class.
In most cases, one should use C<_::does> or C<_::is_instance> instead.

B<$object>:
a scalar possibly containing an object.

B<$class>:
the name of a class:

B<returns>:
a boolean indicating whether the C<$object> inherits from the given C<$class>.
Returns false if the C<$object> parameter isn't actually an object.

= C<$code = _::can $object, $method>

Checks that the object can perform the given method.

    if (my $code = _::can $object, $method) {
        $object->$method(@args);
    }

B<$object>:
a scalar.

B<$method>:
the name of the method to search.

B<returns>:
if the C<$object> can perform the C<$method>, this returns a reference to that method.
A false value is returned in all other cases (the object doesn't know about that method, or the C<$object> argument doesn't actually hold an object).

= C<$bool = _::is_instance $object, $role>
= C<$bool = _::does $object, $role>

Checks that the given C<$object> can perform the C<$role>.

B<$object>:
a scalar possibly containing an object.

B<$role>:
the name of a role.

B<returns>:
a boolean value indicating whether the given C<$object> conforms to the C<$role>.

= C<< any = $maybe_object->_::safecall(method => @args) >>

This will call the C<method> only if the C<$maybe_object> is a blessed object.
We do not check that the object C<can> perform the method, so this might still raise an exception.

Context is propagated correctly to the method call.
If the C<$maybe_object> is not an object, this will simply return.
In scalar context, this evaluates to C<undef>, in list context this is the empty list.

=end :list

=cut

sub blessed(_) {
    goto &Scalar::Util::blessed;
}

{
    no warnings 'once';    ## no critic (ProhibitNoWarnings)
    *class = \&blessed;
}

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

{
    no warnings 'once';    ## no critic (ProhibitNoWarnings)
    *is_instance = \&does;
}

sub can($$) {
    blessed $_[0]
        && $_[0]->can($_[1]);
}

sub safecall($$@) {
    my $self = shift;
    my $meth = shift;
    return if not blessed $self;
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

= C<$dir = _::Dir "foo/bar", "baz">

Creates a new L<Path::Class::Dir|Path::Class::Dir> instance.

= C<$dir = _::File "foo/bar", "baz.txt">

Creates a new L<Path::Class::File|Path::Class::File> instance.

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

$assign_aliases->('Scalar::Util', is_open => 'openhandle');

sub _::prototype ($;$) {
    if (@_ == 2) {
        goto &Scalar::Util::set_prototype if @_ == 2;
    }
    if (@_ == 1) {
        my ($coderef) = @_;
        return prototype $coderef;    # Calls CORE::prototype
    }
    else {
        ## no critic (RequireInterpolationOfMetachars)
        Carp::confess '_::prototype($;$) takes exactly one or two arguments';
    }
}

# This sub uses CamelCase because it's a factory function
sub Dir(@) {    ## no critic (NamingConventions::Capitalization)
    require Path::Class;
    Path::Class::Dir->new(@_);
}

# This sub uses CamelCase because it's a factory function
sub File(@) {    ## no critic (NamingConventions::Capitalization)
    require Path::Class;
    Path::Class::File->new(@_);
}

$assign_aliases->(
    'Data::Dump',
    pp => 'pp',
    dd => 'dd',
);

=head1 RATIONALE

=head4 Context and Package Name

There are a variety of good utility modules like C<Carp> or C<Scalar::Util>.
I noticed I don't import these (in order to avoid namespace pollution), but rather refer to these functions via their fully qualified names (e.g. C<Carp::carp>).
This is ultimately annoying and repetitive.

This module populates the C<_> package (a nod to JavaScript's Underscore.js library) with various helpers so that they can be used without having to import them, with a per-usage overhead of only three characters C<_::>.
The large number of dependencies makes this module somewhat heavyweight, but it avoids the “is C<any> in List::Util or List::MoreUtils”-problem.

In retrospect, choosing the C<_> package name was a mistake:
A certain part of Perl's infrastructure doesn't recognize C<_> as a valid package name (although Perl itself does).
More importantly, Perl's filetest operators can use the magic C<_> filehandle which would interfere with this module if it were intended for anything else than fully qualified access to its functions.
Still, a single underscore is less intrusive than some jumbled letters like C<Ut::any>.

=head4 Scope and Function Naming

This module collects various utility functions that – in my humble opinion – should be part of the Perl language, if the main namespace wouldn't become too crowded as a result.
Because everything is safely hedged into the C<_> namespace, we can go wild without fearing name collisions.
However, a few naming conventions were adhered to:

=for :list
* Functions with a boolean return value start with C<is_>.
* If the source module already provided a sensible name, it is kept to reduce confusion.
* Factory functions that return an object use CamelCase.

=cut

=head1 RELATED MODULES

The following modules were once considered for inclusion or were otherwise influental in the design of this collection:
L<Data::Types|Data::Types>,
L<Data::Util|Data::Util>,
L<Params::Util|Params::Util>,
L<Safe::Isa|Safe::Isa>.

=cut

1;
