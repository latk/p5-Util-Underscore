package Util::Underscore::CallStackFrame;

use strict;
use warnings;

use Carp ();

sub of {
    my ($class, $level) = @_;

    package DB;
    my @caller = CORE::caller($level + 1);
    return undef if not @caller;
    push @caller, [@DB::args];
    return bless \@caller => $class;
}

sub package { shift()->[0] }

sub file { shift()->[1] }

sub line { shift()->[2] }

sub subroutine { shift()->[3] }

sub has_args {
    my ($self) = @_;
    $self->[4] && $self->[11];
}

sub wantarray { shift()->[5] }

sub is_eval {
    my ($self) = @_;
    if ($self->[3] eq '(eval)') {
        my $accessor_object = [ @{ $self }[6, 7] ];
        bless $accessor_object => 'Util::Underscore::CallStackFrame::_Eval';
        return $accessor_object;
    }
    else {
        return !!0;
    }
}

sub is_require { shift()->[7] }

sub hints { shift()->[8] }

sub bitmask { shift()->[9] }

sub hinthash { shift()->[10] }

package Util::Underscore::CallStackFrame::_Eval;

sub source { shift()->[0] }

sub is_require { shift()->[1] }

1;
