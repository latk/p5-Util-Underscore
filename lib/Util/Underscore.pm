package Util::Underscore;

#ABSTRACT: Common helper functions without having to import them
#CONTRIBUTOR: Lukas Atkinson (cpan: AMON) <amon@cpan.org>
#CONTRIBUTOR: Olivier Mengué (cpan: DOLMEN) <dolmen@cpan.org>

use strict;
use warnings;

use version 0.77; our $VERSION = qv('v1.2.1');
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

our $_ASSIGN_ALIASES;

BEGIN {
    $_ASSIGN_ALIASES = sub {
        my ($pkg, %aliases) = @_;
        no strict 'refs';    ## no critic (ProhibitNoStrict)
        while (my ($this, $that) = each %aliases) {
            my $target = "_::${this}";
            my $source = "${pkg}::${that}";
            *{$target} = *{$source}{CODE}
                // Carp::croak "Unknown subroutine $source in _ASSIGN_ALIASES";
        }
    };
}

=head1 FUNCTION REFERENCE

The function reference is split into separate topics which each have their own documentation:

=begin :list

= Scalars

see L<Util::Underscore::Scalars|Util::Underscore::Scalars>

C<alias>,
C<const>,
C<is_dual>,
C<is_identifier>,
C<is_package>,
C<is_plain>,
C<is_readonly>,
C<is_string>,
C<is_bool>,
C<is_tainted>,
C<is_vstring>,
C<new_dual>,
C<chomp>,
C<index>

= Numbers

see L<Util::Underscore::Numbers|Util::Underscore::Numbers>

C<ceil>,
C<floor>,
C<is_int>,
C<is_numeric>,
C<is_uint>

= References

see L<Util::Underscore::References|Util::Underscore::References>

C<ref_addr>,
C<ref_is_weak>,
C<ref_type>,
C<ref_unweaken>,
C<ref_weaken>

= Objects

see L<Util::Underscore::Objects|Util::Underscore::Objects>

C<blessed>,
C<can>,
C<class>,
C<class_does>,
C<class_isa>,
C<does>,
C<is_instance>,
C<is_object>,
C<isa>,
C<safecall>

= List Utils

see L<Util::Underscore::ListUtils|Util::Underscore::ListUtils>

C<all>,
C<any>,
C<each_array>,
C<first>,
C<first_index>,
C<last>,
C<last_index>,
C<max>,
C<max_str>,
C<min>,
C<min_str>,
C<natatime>,
C<none>,
C<pairfirst>,
C<pairgrep>,
C<pairmap>,
C<part>,
C<product>,
C<reduce>,
C<shuffle>,
C<sum>,
C<uniq>,
C<zip>

see L<Util::Underscore::ListUtilsBy|Util::Underscore::ListUtilsBy>

C<max_by>,
C<max_str_by>,
C<min_by>,
C<min_str_by>,
C<uniq_by>,
C<classify>

= Exception handling

see below

C<carp>,
C<carpf>,
C<catch>,
C<cluck>,
C<cluckf>,
C<confess>,
C<confessf>,
C<croak>,
C<croakf>,
C<finally>,
C<try>

= Miscellaneous Functions

see below

C<dd>,
C<Dir>,
C<File>,
C<is_open>,
C<pp>,
C<prototype>

=end :list

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

# load the actual function collections
use Util::Underscore::Scalars    ();
use Util::Underscore::Numbers    ();
use Util::Underscore::References ();
use Util::Underscore::Objects    ();
use Util::Underscore::ListUtils  ();

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
    $_ASSIGN_ALIASES->(
        'Carp',
        carp    => 'carp',
        cluck   => 'cluck',
        croak   => 'croak',
        confess => 'confess',
    );
}

$_ASSIGN_ALIASES->(
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

$_ASSIGN_ALIASES->('Scalar::Util', is_open => 'openhandle');

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

$_ASSIGN_ALIASES->(
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
