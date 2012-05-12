##################################################
#	Reads a logfile in a tail-like style and
#	hands in every read log line/entry to a handler
#	together with a metrics-repo, plus emits all
#	metrics.
#	
#	Author: Jens Riboe (jens.riboe@ribomation.com)
#	Date  : 2012-05-08
##################################################
package Ribomation::LogReader;
use strict;
use Carp;
use Fcntl qw( SEEK_SET SEEK_END );

######################################
# Constructor
# ------------------------------------
sub new {
    my ($target, $file, $fromStart, $debug) = @_;
    my $class    = ref($target) || $target;    
    my $this     = bless {}, $class;
	
	croak('[MetricRepo] Must provide a file new(*)') 
		unless defined $file;
    
	$this->{file}      = $file;
	$this->{debug}     = $debug || 0;
	$this->{fromStart} = $fromStart || 0;
    
    return $this;
}

######################################
# Properties
# ------------------------------------
sub file {
    my ($this) = @_;
    return $this->{file};
}

sub debug {
    my ($this, $value) = @_;
	$this->{debug} = $value if defined $value;
    return $this->{debug};
}

sub fromStart {
    my ($this) = @_;
    return $this->{fromStart};
}

######################################
# Operators
# ------------------------------------

# Runs (continuously) reading each (new) log line/entry.
sub run {
    my ($this, $metricsRepo, $lineHandler)  = @_;
    
    $this->open($this->file);
    $this->toEnd  unless $this->fromStart;
    $lineHandler->setup($metricsRepo);
    while (1) {	
		my $currentPosition = $this->readEntries($metricsRepo, $lineHandler);
		
		my $fileSize = -s $this->file;
		$fileSize    = 0 unless defined($fileSize);
		if ($currentPosition <= $fileSize && $fileSize != 0) { 
            seek $this->output, $currentPosition, SEEK_SET;
        } else { # The logfile has been rolled and we need to re-open it.
            $this->close;
            $this->open($this->file);
        }
	}		
}

# Read log lines/entries until no more to read.
sub readEntries {
    my ($this, $repo, $handler) = @_;
    my $fh      = $this->output;
    my $filePos = 0;
    my $logline;
    
    while (defined($logline = <$fh>)) {         #read one line
        last  if substr($logline, -1) ne "\n";  #break if no NEWLINE found
        $filePos = tell $fh;                    #save current file pos
        chomp($logline);                        #chop off NEWLINE
		
		$handler->handle($logline, $repo);
		$handler->beforeEmit($repo);
		$repo->emit;
		$handler->afterEmit($repo);		
    }

    return tell $fh;
}


######################################
# File Operations
# ------------------------------------
sub output {
    my ($this) = @_;
    return $this->{output};
}

sub open {
    my ($this, $file) = @_;
    
    croak "No logfile defined"  unless defined $file;
    open $this->{output}, '<', $file
        || croak "Cannot open logfile '" . $file . "': $!\n";    
}

sub toEnd {
    my ($this) = @_;    
    my $fh     = $this->output;

    print "Moved to end of file: ", tell $fh, "\n" 
		if (seek $this->output, -1, SEEK_END) && ($this->debug);
}

sub close {
    my ($this) = @_;
    close $this->output;
}






######################################
1;
