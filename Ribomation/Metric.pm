##################################################
#	Represents a single metric.
#	
#	Author: Jens Riboe (jens.riboe@ribomation.com)
#	Date  : 2012-05-08
##################################################
package Ribomation::Metric;
use strict;
use Carp;

######################################
# Constructor
# (1) name, valid iscope resource prefix
# (2) type, in [IntCounter, IntAverage, IntRate, LongCounter, LongAverage, StringEvent, Timestamp]
# ------------------------------------
sub new {
    my ($target, $metricName, $metricType) = @_;
    my $class    = ref($target) || $target;    
    my $this     = bless {}, $class;
    
    $this->{name}  = trim( $metricName ) || croak('[Metric] Must specify a metric name');
    $this->{type}  = trim( $metricType ) || 'IntAverage';
    $this->{value} = 0;   
    $this->{count} = 0;   
    
    return $this;
}

######################################
# Properties
# ------------------------------------
sub name {
    my ($this) = @_;
    return $this->{name};
}

sub type {
    my ($this) = @_;
    return $this->{type};
}

sub count {
    my ($this) = @_;
    return $this->{count};
}

sub value {
    my ($this) = @_;
	return 0               if ($this->{count} == 0);
	return $this->{value}  if ($this->{count} == 1);
    return int($this->{value} / $this->{count});
}

######################################
# Operators
# ------------------------------------

sub add {
    my ($this, $value) = @_;
	croak('[Metric] Must provide a value to add(*)') unless defined($value);
    $this->{value} += $value;
	$this->{count} += 1;
}

sub reset {
    my ($this) = @_;
    $this->{value} = 0;        
    $this->{count} = 0;        
}

sub toString() {
    my ($this) = @_;
	my $name  = $this->name;
    my $type  = $this->type;
    my $value = $this->value;
    return qq(Metric[name=$name, value=$value, type=$type]);
}

######################################
# Emitters
# ------------------------------------

sub asXML {
    my ($this) = @_;
    my $name  = $this->name;
    my $type  = $this->type;
    my $value = $this->value;

    return qq(<metric type="$type" name="$name" value="$value"/>);
}

sub asURI {
    my ($this) = @_;
    my $name  = $this->name;
    my $type  = $this->type;
    my $value = $this->value;
      
    return qq(?metricType=$type&metricName=$name&metricValue=$value);
}

sub asSimple {
    my ($this) = @_;
    my $name  = $this->name;
    my $value = $this->value;
      
    return qq($name=$value);
}

######################################
# Internal Helpers
# ------------------------------------
sub trim {
    my ($txt) = @_;
    return undef unless defined($txt) && length($txt) > 0;

    $txt =~ s/^\s*(.*)\s*$/$1/;
    $txt =~ s/&/&amp;/g;
    $txt =~ s/</&lt;/g;
    $txt =~ s/>/&gt;/g;
    $txt =~ s/"/&quot;/g;
    $txt =~ s/'/&apos;/g;

    return $txt;
}

######################################
1;
