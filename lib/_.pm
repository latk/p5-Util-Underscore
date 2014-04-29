# this matches, but perlcritic seems to use retarded regexes that don't get this.
## no critic (Modules::RequireFilenameMatchesPackage)
package _;

# PODNAME: _.pm
# ABSTRACT: do not use this module directly

use strict;
use warnings;

use version 0.77; our $VERSION = qv('0.1.0');

use Carp ();

my $blow_up = sub {

    # Unload ourselves, so that "require _" gets trapped each time.
    # However, this is only respected by Perl in the $_WE_COME_IN_PEACE mode.
    delete $INC{'_.pm'};

    # be silent if this is being loaded by Util::Underscore
    ## no critic (ProtectPrivateVars)
    return 1 if ($Util::Underscore::_WE_COME_IN_PEACE // q[]) eq 'pinky swear';

    # loudly complain otherwise.
    Carp::confess qq(The "_" package is internal to Util::Underscore)
        . qq(and must not be imported directly.\n);
};

{
    no warnings 'redefine';    ## no critic (ProhibitNoWarnings)

    sub import {
        return $blow_up->();
    }
}

# End with a true value in the $_WE_COME_IN_PEACE mode,
# otherwise use this as a chance to blow up
# – "import" has already been compiled after all.
## no critic (Modules::RequireEndWithOne)
$blow_up->();

__END__

=head1 DESCRIPTION

Do not use this module directly.
The "_" package is internal to L<Util::Underscore|Util::Underscore>,
and only serves as a placeholder.

Any attempt to use, require, or import this module should result in an error message.

The functions in the C<_> namespace are documented in the L<Util::Underscore|Util::Underscore> documentation.
