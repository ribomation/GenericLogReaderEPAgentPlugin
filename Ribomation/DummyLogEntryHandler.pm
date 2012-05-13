package Ribomation::DummyLogEntryHandler;
use strict;
use Carp;
use parent 'Ribomation::LogEntryHandler';

######################################
# Constructor
# ------------------------------------
sub new {
    my ($target) = @_;
    my $class    = ref($target) || $target;    
    my $this     = $class->SUPER::new();    
    return $this;
}

######################################
# handle(logline, metricsRepo)
# ------------------------------------
sub handle {
	my ($this, $logline, $repo) = @_;
	print "[DummyLogEntryHandler] '$logline'\n" if $this->debug;
	$repo->metric('Dummy|Metric:Value')->add(1) if defined $repo;
}

# ---------------------------------------
# Mandatory return value of a Perl module
1;
