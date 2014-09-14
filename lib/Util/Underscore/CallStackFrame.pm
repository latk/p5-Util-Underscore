package Util::Underscore::CallStackFrame;

use strict;
use warnings;

use Carp ();

sub of {
    my ($class, $level) = @_;
    
    my @caller = CORE::caller($level + 1);
    return if not @caller;
    push @caller, [@DB::args];
    return bless \@caller => $class;
}

# 0
sub package { }

# 1
sub file { }

# 2
sub line { }

# 3
sub subroutine { }

# 4
sub has_args { }

# 5, 11=@DB::args
sub wantarray { }

# _, 3, 6, 7
sub is_eval {
    # FIXME mock
    return bless [] => 'Util::Underscore::CallStackFrame::Eval';
}

# 6
sub is_require { }

# 8
sub hints { }

# 9
sub bitmask { }

# 10
sub hinthash { }

package Util::Underscore::CallStackFrame::Eval;

# 0
sub source { }

# 1
sub  is_require { }

1;
