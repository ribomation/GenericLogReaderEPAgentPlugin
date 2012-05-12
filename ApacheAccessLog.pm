#############################################
# Sample Apache HTTPd access log-reader
# The log-format expected below is based on
# a non-standard settings.
# Ensure you check/update the parsing rules.
# ------------------------------------------

package ApacheAccessLog;
use strict;
use warnings;
use Carp;
use parent 'Ribomation::LogEntryHandler';
use Switch;

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
# Handle log-line
# ------------------------------------
sub handle {
	my ($this, $logline, $repo) = @_;
	
	### 123.456.789.012 - - [01/Apr/2012:13:14:15 +0200] "POST /app/operation HTTP/1.1" 200 1234
	if ($logline =~ /^([\d.]+) - - \[(.+)\] \"POST (.+) HTTP\/1\.1\" (\d+) (\d+)$/) {
		print "[ApacheAccessLog] INPUT '$logline'\n"  
			if $this->debug;
			
		my $ip        = $1;
		my $timestamp = $2;
		my $request   = $3;
		my $code      = $4; $code = code2text($code);
		my $elapsed   = $5;		
		print "[ApacheAccessLog] IP=$ip, TIME=$timestamp, REQ=$request, CODE=$code, ELAPSED=$elapsed ms\n" 
			if $this->debug;
		
		$repo->metric("$request|$code:Elapsed Time [ms]")->add($elapsed) if defined $repo;
		$repo->metric("$request|IP|$ip|$code:Elapsed Time [ms]")->add($elapsed) if defined $repo;		
	}
}

sub code2text {
	my ($code) = @_;
	switch ($code) {
		case 200 {return 'OK'}
		case 201 {return 'Created'}
		case 400 {return 'Bad Request'}
		case 401 {return 'Unauthorized'}
		case 403 {return 'Forbidden'}
		case 404 {return 'Not Found'}
		case 405 {return 'Method Not Allowed'}
		case 406 {return 'Not Acceptable'}
		case 418 {return 'I am a teapot (RFC 2324)'}
		case 500 {return 'Server Error'}
		case 501 {return 'Not Implemented'}
		case 503 {return 'Unavailable'}
	}
	return $code;
}

1;
