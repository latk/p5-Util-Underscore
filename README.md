# NAME

Util::Underscore - Common helper functions without having to import them

# VERSION

version v1.4.2

# SYNOPSIS

    use Util::Underscore;

    _::croak "$foo must do Some::Role" if not _::does($foo, 'Some::Role');

# DESCRIPTION

This module contains various utility functions, and makes them accessible through the `_` package.
This allows the use of these utilities (a) without much per-usage overhead and (b) without namespace pollution.

It contains selected functions from the following modules:
[Carp](https://metacpan.org/pod/Carp),
[Const::Fast](https://metacpan.org/pod/Const::Fast),
[Data::Alias](https://metacpan.org/pod/Data::Alias),
[Data::Dump](https://metacpan.org/pod/Data::Dump),
[List::MoreUtils](https://metacpan.org/pod/List::MoreUtils),
[List::Util](https://metacpan.org/pod/List::Util),
[POSIX](https://metacpan.org/pod/POSIX),
[Scalar::Util](https://metacpan.org/pod/Scalar::Util),
[Try::Tiny](https://metacpan.org/pod/Try::Tiny).

Not all functions from those are available, some have been renamed, and some functions of our own have been added.

# FUNCTION REFERENCE

The function reference is split into separate topics which each have their own documentation:

- Scalars

    see [Util::Underscore::Scalars](https://metacpan.org/pod/Util::Underscore::Scalars)

    `alias`(\*),
    `const`,
    `is_dual`,
    `is_identifier`,
    `is_package`,
    `is_plain`,
    `is_readonly`,
    `is_string`,
    `is_bool`,
    `is_tainted`,
    `is_vstring`,
    `new_dual`,
    `chomp`,
    `index`

    (\*) if [Data::Alias](https://metacpan.org/pod/Data::Alias) is installed.

- Numbers

    see [Util::Underscore::Numbers](https://metacpan.org/pod/Util::Underscore::Numbers)

    `ceil`,
    `floor`,
    `is_int`,
    `is_numeric`,
    `is_uint`

- References

    see [Util::Underscore::References](https://metacpan.org/pod/Util::Underscore::References)

    `ref_addr`,
    `ref_is_weak`,
    `ref_type`,
    `ref_unweaken`,
    `ref_weaken`

- Objects

    see [Util::Underscore::Objects](https://metacpan.org/pod/Util::Underscore::Objects)

    `blessed`,
    `can`,
    `class`,
    `class_does`,
    `class_isa`,
    `does`,
    `is_instance`,
    `is_object`,
    `isa`,
    `safecall`

- List Utils

    see [Util::Underscore::ListUtils](https://metacpan.org/pod/Util::Underscore::ListUtils)

    `all`,
    `any`,
    `each_array`,
    `first`,
    `first_index`,
    `last`,
    `last_index`,
    `max`,
    `max_str`,
    `min`,
    `min_str`,
    `natatime`,
    `none`,
    `pairfirst`,
    `pairgrep`,
    `pairmap`,
    `part`,
    `product`,
    `reduce`,
    `shuffle`,
    `sum`,
    `uniq`,
    `zip`

    see [Util::Underscore::ListUtilsBy](https://metacpan.org/pod/Util::Underscore::ListUtilsBy)

    `max_by`,
    `max_str_by`,
    `min_by`,
    `min_str_by`,
    `uniq_by`,
    `classify`

- Exception handling

    see below

    `carp`,
    `carpf`,
    `catch`,
    `cluck`,
    `cluckf`,
    `confess`,
    `confessf`,
    `croak`,
    `croakf`,
    `finally`,
    `try`

- Miscellaneous Functions

    see below

    `caller`,
    `callstack`,
    `dd`,
    `Dir`,
    `File`,
    `is_open`,
    `pp`,
    `process_run`,
    `process_start`,
    `prototype`

## Exception handling

The functions `_::carp`, `_::cluck`, `_::croak`, and `_::confess` from the `Carp` module are available.
They all take a list of strings as argument.
How do they differ from each other?

    Fatal   Warning
    ------- ------- ---------------------
    croak   carp    from call location
    confess cluck   with full stack trace

How do they differ from Perl's builtin `die` and `warn`?
The error messages of `die` and `warn` are located on the line where the exception is raised.
This makes debugging hard when the error points to some internal function of a module you are using,
as this provides no information on where your client code made a mistake.
The `Carp` family of error functions report the error from the point of usage, and optionally provide stack traces.
If you write a module, please use the `Carp` functions instead of plain `die`.

Additionally, the variants `_::carpf`, `_::cluckf`, `_::croakf`, and `_::confessf` are provided.
These take a `sprintf` patterns as first argument: `_::carpf "pattern", @arguments`.

To handle errors, the following keywords from `Try::Tiny` are available:

- `_::try`
- `_::catch`
- `_::finally`

They are all direct aliases for their namesakes in `Try::Tiny`.

## Miscellaneous Functions

- `$fh = _::is_open $fh`

    wrapper for `Scalar::Util::openhandle`

- `$str = _::prototype \&code`
- `_::prototype \&code, $new_proto`

    gets or sets the prototype, wrapping either `CORE::prototype` or `Scalar::Util::set_prototype`

- `$dir = _::Dir "foo/bar", "baz"`

    Creates a new [Path::Class::Dir](https://metacpan.org/pod/Path::Class::Dir) instance.

- `$dir = _::File "foo/bar", "baz.txt"`

    Creates a new [Path::Class::File](https://metacpan.org/pod/Path::Class::File) instance.

`Data::Dump` is an alternative to `Data::Dumper`.
The main difference is the output format: `Data::Dump` output tends to be easier to read.

- `$str = _::pp @values`

    wrapper for `Data::Dump::pp`

- `_::dd @values`

    wrapper for `Data::Dump::dd`.

This module also includes an object-oriented interface to the callstack.
See [Util::Underscore::CallStackFrame](https://metacpan.org/pod/Util::Underscore::CallStackFrame) for further details.

- `@stack_frames = _::callstack`
- `@stack_frames = _::callstack $start_from_level`

    Assembles a list of call stack frames.

    **$start\_from\_level**:
    The level starting from which frames should be constructed.
    For example, `1` would start from the immediate caller, whereas `0` includes the current frame as well.
    If ommited, uses `1`.

    **returns**:
    A list of `Util::Underscore::CallStackFrame` objects.

- `$stack_frame = _::caller`
- `$stack_frame = _::caller $level`

    Assembles an object representing a specific call stack frame.

    **$level**:
    The level of which the call stack frame is to be returned.
    A value of `1` would return the immediate caller, whereas `0` would indicate the current frame.
    If ommited, uses `1`.

    **returns**:
    A `Util::Underscore::CallStackFrame` instance representing the requested stack frame.
    If no such frame exists, `undef` is returned.

For invoking external commands, Perl offers the `system` command, various modes for `open`, and the backtick operator (`qx//`).
However, these modes encourage interpolating variables directly into a string, which opens up shell injection issues.
In fact, `open` and `system` can't avoid shell injection when piping or redirection is involved.
The [IPC::Run](https://metacpan.org/pod/IPC::Run) module avoids this by offering a flexible interface for launching and controlling external processes.

- `$success = _::process_run COMMAND_SPEC`

    Spawns the specified command(s), and blocks until completion.

    **COMMAND\_SPEC**:
    An IPC::Run harness specification.

    **returns**:
    A boolean indicating whether all spawned processes completed without errors (all sub-processes have exit code zero).
    This is inverse to Perl's built in `system` function!

    Example:

        my $data = "stuff you want to display with a pager.";

        # The contents of $data are entered via STDIN
        _::process_run ['less', '-R'], \$data
            or die "Couldn't run less: $?";

        # To do that same thing using builtin functions, we'd have to do:
        my $less_pid = open my $less_fh, '|-', 'less', '-R' or die "Couldn't start less: $!";
        print $less_fh $data;
        close $less_fh or die "Couldn't close pipe to less: $!";
        waitpid $less_pid, 0;

- `$process = _::process_start COMMAND_SPEC`

    Spawns the specified command(s).

    **COMMAND\_SPEC**:
    An IPC::Run harness specification.

    **returns**:
    A IPC::Run object that represents the launched process(es).
    To await completion, call `$process->finish`.

# RATIONALE

#### Context and Package Name

There are a variety of good utility modules like `Carp` or `Scalar::Util`.
I noticed I don't import these (in order to avoid namespace pollution), but rather refer to these functions via their fully qualified names (e.g. `Carp::carp`).
This is ultimately annoying and repetitive.

This module populates the `_` package (a nod to JavaScript's Underscore.js library) with various helpers so that they can be used without having to import them, with a per-usage overhead of only three characters `_::`.
The large number of dependencies makes this module somewhat heavyweight, but it avoids the “is `any` in List::Util or List::MoreUtils”-problem.

In retrospect, choosing the `_` package name was a mistake:
A certain part of Perl's infrastructure doesn't recognize `_` as a valid package name (although Perl itself does).
More importantly, Perl's filetest operators can use the magic `_` filehandle which would interfere with this module if it were intended for anything else than fully qualified access to its functions.
Still, a single underscore is less intrusive than some jumbled letters like `Ut::any`.

#### Scope and Function Naming

This module collects various utility functions that – in my humble opinion – should be part of the Perl language, if the main namespace wouldn't become too crowded as a result.
Because everything is safely hedged into the `_` namespace, we can go wild without fearing name collisions.
However, a few naming conventions were adhered to:

- Functions with a boolean return value start with `is_`.
- If the source module already provided a sensible name, it is kept to reduce confusion.
- Factory functions that return an object use CamelCase.

# RELATED MODULES

The following modules were once considered for inclusion or were otherwise influental in the design of this collection:
[Data::Types](https://metacpan.org/pod/Data::Types),
[Data::Util](https://metacpan.org/pod/Data::Util),
[Params::Util](https://metacpan.org/pod/Params::Util),
[Safe::Isa](https://metacpan.org/pod/Safe::Isa).

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/latk/p5-Util-Underscore/issues](https://github.com/latk/p5-Util-Underscore/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Lukas Atkinson (cpan: AMON) <amon@cpan.org>

## CONTRIBUTOR

Olivier Mengué (cpan: DOLMEN) <dolmen@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Lukas Atkinson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
