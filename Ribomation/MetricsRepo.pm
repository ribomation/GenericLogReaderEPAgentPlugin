##################################################
#	Represents a collection of metrics.
#	Each metric is identified by its name.
#	
#	Author: Jens Riboe (jens.riboe@ribomation.com)
#	Date  : 2012-05-08
##################################################
package Ribomation::MetricsRepo;
use strict;
use Carp;

my $lwpInstalled = 0;
eval {
	require LWP::Simple;
	LWP::Simple->import();
	$lwpInstalled = 1;
};

######################################
# Constructor
# ------------------------------------
sub new {
    my ($target, $prefix, $xml, $url) = @_;
    my $class    = ref($target) || $target;    
    my $this     = bless {}, $class;
	
	croak('[MetricRepo] Must provide a metric name prefix to new(*)') 
		unless defined $prefix;
    
    $this->{metrics} = {};   
	$this->{prefix}  = $prefix;
	$this->{xml}     = $xml || 1;
	$this->{url}     = $url;
    
    return $this;
}

######################################
# Properties
# ------------------------------------

sub prefix {
	my ($this) = @_;
	return $this->{prefix};
}

sub url {
	my ($this, $value) = @_;
	$this->{url} = $value  if defined $value;
	return $this->{url};
}

sub xml {
	my ($this, $value) = @_;
	$this->{xml} = $value  if defined $value;
	return $this->{xml};
}


######################################
# Operations
# ------------------------------------

# Returns a metric (creates it, if needed)
sub metric {
    my ($this, $name, $type) = @_;
	croak('[MetricRepo] Must provide a name to get(*)') unless defined($name);
	
	my $metrics = $this->{metrics};
	unless (defined $metrics->{$name}) {
		$metrics->{$name} = new Ribomation::Metric($this->prefix . '|' . $name, $type);
	}
	return $metrics->{$name};
}

# Invokes reset() on each metric in the repo.
sub reset {
	my ($this) = @_;
	my $metrics = $this->{metrics};
	foreach my $metric (values %$metrics) {
		$metric->reset;
	}
}

# Emits each metric in the repo, using the repo settings
# such as XML and URL.
sub emit {
	my ($this) = @_;
	my $metrics = $this->{metrics};
	foreach my $m (values %$metrics) {
		if ($this->url) {
			croak "[ERROR] CPAN module LWP::Simple not installed. Cannot push metrics to EPA via HTTP\n" 
				unless ($lwpInstalled && defined &get);
	
			my $request  = $this->url . $m->asURI;
            my $response = get($request);
            carp "[WARNING] Failed HTTP GET url='$request'\n" unless defined $response;
		} elsif ($this->xml) {
			print STDOUT $m->asXML, "\n";
		} else {
			print STDOUT $m->asSimple, "\n";
		}
	}
}

######################################
1;
