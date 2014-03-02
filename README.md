# Util::Underscore

Common helper functions without having to import them

## SYNOPSIS

    use Util::Underscore;

    _::croak "$foo must do Some::Role" if not _::does($foo, 'Some::Role');

## DESCRIPTION
    
This module contains various utility functions, and makes them accessible through the "_" package. This allows the use of these utilities (a) without much per-usage overhead and (b) without namespace pollution.

It contains functions from the following modules:

 *  `Scalar::Util`
 *  `List::Util`
 *  `List::MoreUtils`
 *  `Carp`
 *  `Safe::Isa`, which contains convenience functions for `UNIVERSAL`
 *  `Try::Tiny`

Not all functions from those are available, and some have been renamed.

## INSTALLATION

This is an ordinary CPAN module. E.g. install like

    $ cpanm Util::Underscore

## COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Lukas Atkinson.

This is free software, licensed under:

[The GNU General Public License, Version 3, June 2007](https://www.gnu.org/licenses/gpl-3.0-standalone.html)
