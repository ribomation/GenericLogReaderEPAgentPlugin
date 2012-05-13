Introscope EPAgent Generic LogReader
====================================

Introscope EPAgent stateful plugin, for extracting metric data from logfiles.

Disclaimer
----------

*Introscope is a commercial tool for application performance management (APM) of (large) Java applications in production. EPAgent is a stand-alone agent that can execute scripts that retrieve performance from non-Java systems. You need to have a valid license of Introscope.*

Requirements
------------

* Valid license for CA-Wily Introscope
* EPAgent installed
* Perl 5
* LWP::Simple CPAN extension installed (*OPTIONAL*)

Installation instructions
---------------------------------

Grab the Perl files from GitHub (https://github.com/ribomation/GenericLogReaderEPAgentPlugin) and copy them into `$EPA_HOME/epaplugins/ribomation`, preserving the directory structure. Before configuring EPA, run the log-reader from the command-line, to figure out the appropriate options. 

Example
---------------------------------
The command below runs the log-reader with a sample log-entry handler named *ApacheAccessLog*, reading from the file *sample.log*, setting the metric name root to *Apache Access* and finally, start reading from the beginning of the file (instead of from the end). You can se the typically EPA metric statements printed out to stdout, which is inteded to be read by EPAgent.

	$ cd $EPA_HOME
	$ perl epaplugins/ribomation/LogReader.pl --handler=ApacheAccessLog --file=sample.log --prefix='Apache Access' --start
	<metric type="IntAverage" name="Apache Access|/ws/GetMessage|IP|123.456.789.123|OK:Elapsed Time [ms]" value="433"/>
	<metric type="IntAverage" name="Apache Access|/ws|IP|123.456.789.123|OK:Elapsed Time [ms]" value="779"/>
	<metric type="IntAverage" name="Apache Access|/ws/GetMessage|IP|123.456.789.123|OK:Elapsed Time [ms]" value="433"/>
	<metric type="IntAverage" name="Apache Access|/ws|IP|1123.456.789.123|OK:Elapsed Time [ms]" value="2128"/>
	<metric type="IntAverage" name="Apache Access|/ws|IP|1123.456.789.123|OK:Elapsed Time [ms]" value="394"/>
		 . . .


Configuration
=============

Parameters
----------

<table>
	<tr> <th>Parameter</th> <th>Required</th> <th>Argument</th>             <th>Default</th>  <th>Description</th> </tr>
	<tr> <td>handler</td>   <td>YES</td>      <td>LogEntryHandlerName</td>  <td></td>         <td>Name of Perl module to handle each log entry/line</td> </tr>
	<tr> <td>file</td>      <td>YES</td>      <td>/path/to/logfile</td>     <td></td>         <td>Name of log-file to read.</td> </tr>
	<tr> <td>prefix</td>    <td>YES</td>      <td>'Root Node|Sub Node'</td> <td>Ribomation LogReader</td> <td>Metric name root.</td> </tr>
	<tr> <td>start</td>     <td></td>         <td></td>        <td></td>    <td>If given, start reading from the beginning of the file.</td> </tr>
	<tr> <td>url</td>       <td></td>         <td>http://EPAhost:EPAport/</td> <td></td>      <td>If given, runs the script stand-alone and push the metric feed using HTTP GET to the EPAgent (must have the HTTP port configured).</td> </tr>
	<tr> <td>debug</td>     <td></td>         <td></td>                     <td></td>         <td>If given, prints out diagnostic outputs.</td> </tr>
	<tr> <td>help</td>      <td></td>         <td></td>                     <td></td>         <td>if given, prints out the list of parameters and quit.</td> </tr>
</table>

In addition, if your log-entry handler module is located somewhere else in the file-system, you might want to add the directory path to Perl's INC, using: `-I /path/to/dir`

EPAgent
-------
The log-reader is a stateful EPAgent plugin, which means that EPA starts it once and keeps it running. The following snippet shows how the log-reader can be configured in the `$EPA_HOME/IntroscopeEPAgent.properties` file.

	introscope.epagent.plugins.stateful.names=LOGREADER
	introscope.epagent.stateful.LOGREADER.command=perl epaplugins/ribomation/LogReader.pl --handler=MyLogHandler --file=/path/to/logfile --prefix='My Service'

In addition, if you want to run the log-reader stand-alone and push metrics to an EPAgent isntance using HTTP GET, you must enable the HTTP PORT in the `$EPA_HOME/IntroscopeEPAgent.properties` file.

	introscope.epagent.config.httpServerPort=10000


LogEntryHandler
===============

In order to use this log-reader, you need to write a log-entry/line handler Perl module. This module must be a sub-class to *Ribomation::LogEntryHandler* and at least override method `handle($ligline, $metricsRepo)`. This code skeleton (taken from Ribomation::DummyLogEntryHandler) helps you get started.

	package Ribomation::MyLogEntryHandler;
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

Method handle(logline, metricsRepo)
-----------------------------------

The parameters to handle() are the *just read* log-line and a MetricsRepo object. The intended actions within handle() are

1. Parse the line and extract the interesting fragments into variables.
2. Emit one or more metrics based on the extracted data, using the provided repo object.

The repo object is first asked for a metric object, which is created if needed.

	MetricsRepo::metric(metricName [, metricType]) ==> Metric
	
The metric name must be a valid Introscope metric name suffix, such as `Whatever|Access:Time [ms]`. This name is appended to the prefix parameter value of the log-reader.

The optional metric type must be one of

* IntCounter
* IntAverage (*DEFAULT*)
* IntRate
* LongCounter
* LongAverage
* StringEvent
* Timestamp

The add() method of Metric, aggregates the value(s) if invoked more than once during on single call of handle(). 

	Metric::add(value)

After each handle() invokation the log-reader emits (*MetricRepo::emit*) the collected metric values in the repo and resets (*Metric::reset*) each metric object.

Additonal methods to override
-----------------------------

The super-class (*Ribomation::LogEntryHandler*) provides some other methods that sometimes might come in-handy.

	setup(metricsRepo)

Invoked once before start reading the log entries.

	beforeEmit(metricsRepo)

Invoked before emitting all metrics. Can be used to adjust the metrics.
	
	afterEmit(metricsRepo)

Invoked after emitting all metrics.

	debug([value])

If invoked without an argument, returns the current value of flag *debug*. If invoked with 0 or 1, sets the flag.







