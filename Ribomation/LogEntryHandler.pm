##################################################
#	Invoked for each read log (line) entry.
#	This class is supposed to be sub-classed, where
#	at least function handle() is overridden.
#	
#	Author: Jens Riboe (jens.riboe@ribomation.com)
#	Date  : 2012-05-08
##################################################
package Ribomation::LogEntryHandler;
use strict;
use Carp;

######################################
# Constructor
# ------------------------------------
sub new {
    my ($target) = @_;
    my $class    = ref($target) || $target;    
    my $this     = bless {}, $class;
    
    return $this;
}

######################################
# Operations
# ------------------------------------

# Handles/processes a single log line/entry.
# Typically, parts are extracted from the line and one or more
# metrics are updated.
sub handle {
	my ($this, $logline, $metricsRepo) = @_;
	croak('[LogEntryHandler] Must (at least) override handle(*)');
}

# Invoked once before reading log entries.
sub setup {
	my ($this, $metricsRepo) = @_;
}

# Invoked before emitting all metrics.
sub beforeEmit {
	my ($this, $metricsRepo) = @_;
}

# Invoked after emitting all metrics.
sub afterEmit {
	my ($this, $metricsRepo) = @_;
}

sub debug {
	my ($this, $value) = @_;
	$this->{debug} = $value if defined $value;
	return $this->{debug};
}

######################################
1;
