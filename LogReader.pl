#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use Getopt::Long qw(HelpMessage);
use Ribomation::LogReader;
use Ribomation::Metric;
use Ribomation::MetricsRepo;
use Ribomation::LogEntryHandler;

my $file;
my $handler;
my $prefix    = 'Ribomation LogReader';
my $debug     = 0;
my $fromStart = 0;
my $xml       = 1;
my $url;
my $help      = 0;

my $usage = "usage: $0 --<option>=<value> ...
Options:
  handler=LogEntryHandler       Name of Perl module that handles each log line (REQUIRED)
  file=/path/to/logfile         Path to log file to read (REQUIRED)
  prefix='Root Node|Sub Node'   Metric name prefix to use for each metric
  url=http://epahost:epaport    Used when metrics should be sent to EPA using HTTP GET
  start                         If log reading should begin at the start of the file
  debug                         Enable diagnostic outputs
";

parseArgs();
validateArgs();
run();

exit 0;

######################################
# Helpers
# ------------------------------------
sub parseArgs {
	GetOptions(
        'file=s'      => \$file,
        'handler=s'   => \$handler,
        'prefix:s'    => \$prefix,
        'start'       => \$fromStart,
        'url:s'       => \$url,
        'debug'       => \$debug,
        'help'        => \$help,
    ); 
	
	if ($help) {print $usage; exit 0;}
}

sub validateArgs {
	die "[LogReader] Must provide a log-entry handler\n$usage\n" 
		if isBlank($handler);
		
	loadHandler($handler);
		
	die "[LogReader] Must provide a logfile\n$usage\n" 
		if isBlank($file);	
		
	die "[LogReader] Cannot open/read logfile $file\n$usage\n"
		unless canRead($file);

	$url = adjustUrl($url) 
		unless isBlank($url);		
}

sub loadHandler {
	my ($module) = @_;
	eval "require $module; " or die "Failed to load $module: $@\n";
	my $obj = new $module();
}

sub run {
	#my ($xxx) = @_;
		
	my $logReader   = new Ribomation::LogReader($file, $fromStart, $debug);
	my $metricsRepo = new Ribomation::MetricsRepo($prefix, $xml, $url);
	my $lineHandler = $handler->new();
	$lineHandler->debug($debug);
	
	print "[LogReader] Starts reading logfile '$file' from the ".($fromStart ? 'start' : 'end')  if $debug;
	$logReader->run($metricsRepo, $lineHandler);		
}

sub isBlank {
    my $txt = shift;
    return !(defined $txt) || ($txt =~ /^\s*$/);
}

sub canRead {
	my $file = shift;
	open(FILE, '<', $file) || return 0;
	close FILE;
	return 1;
}

sub adjustUrl {
    my $url = shift;
    $url = $url . '/' unless $url =~ m|.+/$|;
    return $url;
}

